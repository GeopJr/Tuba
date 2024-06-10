public class Tuba.Views.Notifications : Views.Timeline, AccountHolder, Streamable {
	protected InstanceAccount? last_account = null;
	private Binding badge_number_binding;
	private Binding filtered_notifications_count_binding;
	private Adw.Banner notifications_filter_banner;

	public int32 filtered_notifications {
		set {
			if (notifications_filter_banner == null) return;

			if (value > 0) {
				notifications_filter_banner.title = GLib.ngettext (
					"%d Filtered Notification",
					"%d Filtered Notifications",
					(ulong) value
				).printf (value);
				notifications_filter_banner.revealed = true;
			} else {
				notifications_filter_banner.revealed = false;
			}
		}
	}

	construct {
		url = "/api/v1/notifications";
		label = _("Notifications");
		icon = "tuba-bell-outline-symbolic";
		accepts = typeof (API.Notification);
		badge_number = 0;
		needs_attention = false;
		empty_state_title = _("No Notifications");

		stream_event[InstanceAccount.EVENT_NOTIFICATION].connect (on_new_post);

		#if DEV_MODE
			app.dev_new_notification.connect (node => {
				try {
					model.insert (0, Entity.from_json (accepts, node));
				} catch (Error e) {
					warning (@"Error getting Entity from json: $(e.message)");
				}
			});
		#endif

		notifications_filter_banner = new Adw.Banner ("") {
			use_markup = true,
			button_label = _("View"),
			revealed = false
		};
		notifications_filter_banner.button_clicked.connect (on_notifications_filter_banner_button_clicked);

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			vexpand = true
		};
		box.append (notifications_filter_banner);
		scrolled.child = box;
		box.append (content_box);
	}

	private void on_notifications_filter_banner_button_clicked () {
		app.main_window.open_view (new Views.NotificationRequests ());
	}

	public override bool should_hide (Entity entity) {
		var notification_entity = entity as API.Notification;
		if (notification_entity != null && notification_entity.status != null) {
			return base.should_hide (notification_entity.status);
		}

		return false;
	}

	~Notifications () {
		warning ("Destroying Notifications");
		stream_event[InstanceAccount.EVENT_NOTIFICATION].disconnect (on_new_post);
		badge_number_binding.unbind ();
	}

	public override void on_account_changed (InstanceAccount? acc) {
		base.on_account_changed (acc);

		if (badge_number_binding != null)
			badge_number_binding.unbind ();

		if (filtered_notifications_count_binding != null)
			filtered_notifications_count_binding.unbind ();

		badge_number_binding = accounts.active.bind_property (
			"unread-count",
			this,
			"badge-number",
			BindingFlags.SYNC_CREATE,
			(b, src, ref target) => {
				var unread_count = src.get_int ();
				target.set_int (unread_count);
				this.needs_attention = unread_count > 0;
				Tuba.Mastodon.Account.PLACE_NOTIFICATIONS.badge = unread_count;

				return true;
			}
		);

		filtered_notifications_count_binding = accounts.active.bind_property (
			"filtered-notifications-count",
			this,
			"filtered-notifications",
			BindingFlags.SYNC_CREATE,
			on_filtered_notifications_count_change
		);
	}

	private bool on_filtered_notifications_count_change (Binding binding, Value from_value, ref Value to_value) {
		to_value.set_int (from_value.get_int ());
		return true;
	}

	public override void on_shown () {
		base.on_shown ();
		if (account != null) {
			account.read_notifications (
				account.last_received_id > account.last_read_id
					? account.last_received_id
					: account.last_read_id
			);

			if (account.probably_has_notification_filters)
				update_filtered_notifications ();
		}
	}

	public override void on_hidden () {
		base.on_hidden ();
		if (account != null) {
			account.unread_count = 0;
		}
	}

	public void update_filtered_notifications () {
		new Request.GET ("/api/v1/notifications/policy")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				if (node == null) {
					accounts.active.filtered_notifications_count = 0;
					return;
				};

				var policies = API.NotificationFilter.Policy.from (node);
				if (policies.summary != null) {
					accounts.active.filtered_notifications_count = policies.summary.pending_notifications_count;
				}
			})
			.on_error ((code, message) => {
				accounts.active.filtered_notifications_count = 0;
				if (code == 404) {
					accounts.active.probably_has_notification_filters = false;
				} else {
					warning (@"Error while trying to get notification policy: $code $message");
				}
			})
			.exec ();
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.instance)/api/v1/streaming?stream=user:notification&access_token=$(account.access_token)"
			: null;
	}
}
