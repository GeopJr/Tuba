[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/notification_settings.ui")]
public class Tuba.Dialogs.NotificationSettings : Adw.Dialog {
	public signal void filters_changed ();

	class NotificationRow : Adw.ActionRow {
		public bool active {
			get { return row_switch.active; }
			set { row_switch.active = value; }
		}

		public string kind { get; set; }

		Gtk.Switch row_switch;
		public NotificationRow (string kind, string title, string icon) {
			row_switch = new Gtk.Switch () {
				valign = Gtk.Align.CENTER
			};
			this.activatable_widget = row_switch;

			this.title = title;
			this.kind = kind;
			this.active = !(kind in settings.notification_filters);

			this.add_prefix (new Gtk.Image.from_icon_name (icon) {
				valign = Gtk.Align.CENTER
			});

			this.add_suffix (row_switch);
		}
	}

	~NotificationSettings () {
		notification_rows = {};
		debug ("Destroying Dialog NotificationSettings");
	}

	[GtkChild] protected unowned Adw.ToastOverlay toast_overlay;
	[GtkChild] protected unowned Gtk.Button clear_button;
	[GtkChild] protected unowned Adw.PreferencesGroup filters_group;
	[GtkChild] protected unowned Adw.PreferencesGroup filtered_notifications_group;
	[GtkChild] protected unowned Adw.SwitchRow filter_notifications_following_switch;
	[GtkChild] protected unowned Adw.SwitchRow filter_notifications_follower_switch;
	[GtkChild] protected unowned Adw.SwitchRow filter_notifications_new_account_switch;
	[GtkChild] protected unowned Adw.SwitchRow filter_notifications_dm_switch;

	NotificationRow[] notification_rows;
	construct {
		notification_rows = {
			new NotificationRow (InstanceAccount.KIND_MENTION, _("Mentions"), "tuba-chat-symbolic"),
			new NotificationRow (InstanceAccount.KIND_FAVOURITE, _("Favorites"), "tuba-starred-symbolic"),
			new NotificationRow (InstanceAccount.KIND_REBLOG, _("Boosts"), "tuba-media-playlist-repeat-symbolic"),
			new NotificationRow (InstanceAccount.KIND_POLL, _("Polls"), "tuba-check-round-outline-symbolic"),
			new NotificationRow (InstanceAccount.KIND_EDITED, _("Post Edits"), "document-edit-symbolic"),
			new NotificationRow (InstanceAccount.KIND_FOLLOW, _("Follows"), "contact-new-symbolic")
		};

		foreach (var row in notification_rows) {
			filters_group.add (row);
		};

		this.closed.connect (save);
		setup_notification_filters ();
	}

	private void save () {
		bool changed = false;
		string[] new_filters = {};

		foreach (var row in notification_rows) {
			if (!row.active)
				new_filters += row.kind;
		};

		if (new_filters.length != settings.notification_filters.length) {
			changed = true;
		} else {
			foreach (var filter in new_filters) {
				if (!(filter in settings.notification_filters)) {
					changed = true;
					break;
				}
			};
		}

		if (changed) {
			settings.notification_filters = new_filters;
			filters_changed ();
		}

		if (notification_filter_policy_status != null) {
			bool nfp_changed = false;
			notification_filter_policy_status.@foreach (entry => {
				if (((Adw.SwitchRow) entry.key).active != (bool) entry.value) {
					nfp_changed = true;
					return false;
				}

				return true;
			});

			if (nfp_changed) {
				var builder = new Json.Builder ();
				builder.begin_object ();

				builder.set_member_name ("filter_not_following");
				builder.add_boolean_value (filter_notifications_following_switch.active);

				builder.set_member_name ("filter_not_followers");
				builder.add_boolean_value (filter_notifications_follower_switch.active);

				builder.set_member_name ("filter_new_accounts");
				builder.add_boolean_value (filter_notifications_new_account_switch.active);

				builder.set_member_name ("filter_private_mentions");
				builder.add_boolean_value (filter_notifications_dm_switch.active);

				builder.end_object ();

				new Request.PUT ("/api/v1/notifications/policy")
					.with_account (accounts.active)
					.body_json (builder)
					.exec ();
			}

			notification_filter_policy_status.clear ();
		}
	}

	[GtkCallback] private void clear_all_notifications () {
		var dlg = new Adw.AlertDialog (
			_("Clear All Notifications?"),
			null
		);

		dlg.add_response ("no", _("Cancel"));
		dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("yes", _("Clear"));
		dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
		dlg.choose.begin (this, null, (obj, res) => {
			if (dlg.choose.end (res) == "yes") {
				clear_button.sensitive = false;
				new Request.POST ("/api/v1/notifications/clear")
					.with_account (accounts.active)
					.then (() => {
						clear_button.sensitive = true;
						this.force_close ();
						app.refresh ();
					})
					.on_error ((code, message) => {
						warning (@"Error while trying to clear notifications: $code $message");
						toast_overlay.add_toast (new Adw.Toast (message) {
							timeout = 5
						});
					})
					.exec ();
			}
		});
	}

	private Gee.HashMap<Adw.SwitchRow, bool>? notification_filter_policy_status = null;
	void setup_notification_filters () {
		if (!accounts.active.probably_has_notification_filters) return;

		new Request.GET ("/api/v1/notifications/policy")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				if (node == null) return;

				filtered_notifications_group.visible = true;
				var policies = API.NotificationFilter.Policy.from (node);

				notification_filter_policy_status = new Gee.HashMap<Adw.SwitchRow, bool> ();
				notification_filter_policy_status.set (filter_notifications_following_switch, policies.filter_not_following);
				notification_filter_policy_status.set (filter_notifications_follower_switch, policies.filter_not_followers);
				notification_filter_policy_status.set (filter_notifications_new_account_switch, policies.filter_new_accounts);
				notification_filter_policy_status.set (filter_notifications_dm_switch, policies.filter_private_mentions);

				notification_filter_policy_status.@foreach (entry => {
					((Adw.SwitchRow) entry.key).active = (bool) entry.value;

					return true;
				});
			})
			.on_error ((code, message) => {
				if (code == 404) {
					accounts.active.probably_has_notification_filters = false;
				} else {
					warning (@"Error while trying to get notification policy: $code $message");
				}
			})
			.exec ();
	}
}
