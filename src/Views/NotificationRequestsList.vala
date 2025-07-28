public class Tuba.Views.NotificationRequestsList : Views.Timeline {
	Widgets.NotificationRequest notification_req_wdg;

	public NotificationRequestsList (string account_id, string account_handle, Widgets.NotificationRequest notification_req_wdg) {
		Object (
			url: @"/api/v1/notifications?account_id=$account_id",
			// translators: the variable is a user handle
			label: _("Notifications by %s").printf (account_handle),
			icon: "tuba-bell-outline-symbolic",
			// translators: the variable is a user handle
			empty_state_title: _("No Notifications by %s").printf (account_handle),
			batch_size_min: 20
		);

		this.accepts = typeof (API.Notification);
		this.notification_req_wdg = notification_req_wdg;
	}

	private Gtk.Button dismiss_btn;
	private Gtk.Button accept_btn;
	protected override void build_header () {
		base.build_header ();

		dismiss_btn = new Gtk.Button () {
			icon_name = "user-trash-symbolic",
			css_classes = { "flat", "error" },
			tooltip_text = _("Dismiss")
		};
		dismiss_btn.clicked.connect (on_dismiss);

		accept_btn = new Gtk.Button () {
			icon_name = "tuba-check-round-outline-symbolic",
			css_classes = { "flat", "success" },
			tooltip_text = _("Accept")
		};
		accept_btn.clicked.connect (on_accept);

		header.pack_end (accept_btn);
		header.pack_end (dismiss_btn);
	}

	private void on_dismiss () {
		dismiss_btn.sensitive = accept_btn.sensitive = false;
		notification_req_wdg.on_dismiss ();
		app.main_window.back ();
	}

	private void on_accept () {
		dismiss_btn.sensitive = accept_btn.sensitive = false;
		notification_req_wdg.on_dismiss ();
		app.main_window.back ();
	}
}
