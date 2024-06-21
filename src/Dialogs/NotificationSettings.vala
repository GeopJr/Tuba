public class Tuba.Dialogs.NotificationSettings : Adw.Dialog {
	public signal void filters_changed ();

	// Why is AdwSwitchRow sealed???
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

	Adw.ToastOverlay toast_overlay;
	Gtk.Button clear_button;
	NotificationRow[] notification_rows;
	construct {
		this.title = _("Filter");
		this.content_width = 460;
		this.content_height = 464;

		notification_rows = {
			new NotificationRow (InstanceAccount.KIND_MENTION, _("Mentions"), "tuba-chat-symbolic"),
			new NotificationRow (InstanceAccount.KIND_FAVOURITE, _("Favorites"), "tuba-starred-symbolic"),
			new NotificationRow (InstanceAccount.KIND_REBLOG, _("Boosts"), "tuba-media-playlist-repeat-symbolic"),
			new NotificationRow (InstanceAccount.KIND_POLL, _("Polls"), "tuba-check-round-outline-symbolic"),
			new NotificationRow (InstanceAccount.KIND_EDITED, _("Post Edits"), "document-edit-symbolic"),
			new NotificationRow (InstanceAccount.KIND_FOLLOW, _("Follows"), "contact-new-symbolic")
		};

		var page = new Adw.PreferencesPage ();
		toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			hexpand = true,
			child = page,
			valign = Gtk.Align.CENTER
		};
		var toolbarview = new Adw.ToolbarView () {
			content = toast_overlay
		};

		var headerbar = new Adw.HeaderBar ();
		clear_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			css_classes = { "flat", "error" },
			tooltip_text = _("Clear All Notifications")
		};
		clear_button.clicked.connect (clear_all_notifications);
		headerbar.pack_start (clear_button);
		toolbarview.add_top_bar (headerbar);

		var filters_group = new Adw.PreferencesGroup () {
			title = _("Included Notifications")
		};
		foreach (var row in notification_rows) {
			filters_group.add (row);
		};

		page.add (filters_group);
		this.child = toolbarview;
		this.closed.connect (save);
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
	}

	private void clear_all_notifications () {
		var dlg = new Adw.AlertDialog (
			_("Are you sure you want to clear all notifications?"),
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
}
