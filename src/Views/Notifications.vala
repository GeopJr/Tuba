public class Tuba.Views.Notifications : Views.Timeline, AccountHolder, Streamable {
	protected InstanceAccount? last_account = null;
	private Binding badge_number_binding;

	construct {
		url = "/api/v1/notifications";
		label = _("Notifications");
		icon = "tuba-bell-outline-symbolic";
		accepts = typeof (API.Notification);
		badge_number = 0;
		needs_attention = false;
		empty_state_title = _("No Notifications");

		change_filter (settings.notifications_filter, false);
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
	}

	public override void on_shown () {
		base.on_shown ();
		if (account != null) {
			account.read_notifications (
				account.last_received_id > account.last_read_id
					? account.last_received_id
					: account.last_read_id
			);
		}
	}

	public override void on_hidden () {
		base.on_hidden ();
		if (account != null) {
			account.unread_count = 0;
		}
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.instance)/api/v1/streaming?stream=user:notification&access_token=$(account.access_token)"
			: null;
	}

	const string[] KINDS = {InstanceAccount.KIND_EDITED, InstanceAccount.KIND_MENTION, InstanceAccount.KIND_FAVOURITE, InstanceAccount.KIND_REBLOG, InstanceAccount.KIND_POLL, InstanceAccount.KIND_FOLLOW};
	public void change_filter (string filter_id, bool refresh = true) {
		string new_url = "/api/v1/notifications";
		if (filter_id != "") {
			bool excluded_anything = false;

			new_url = @"$new_url?exclude_types[]=admin.sign_up&exclude_types[]=admin.report";
			foreach (string kind in KINDS) {
				if (kind == filter_id) continue;

				new_url = @"$new_url&exclude_types[]=$kind";
				excluded_anything = true;
			}

			if (!excluded_anything) return;
		}

		if (new_url == this.url) return;
		this.url = new_url;

		if (refresh) {
			page_next = null;
			on_refresh ();
		}
	}
}
