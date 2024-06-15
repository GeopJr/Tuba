public class Tuba.Widgets.NotificationRequest : Gtk.ListBoxRow {
	public signal void dismissed (Request req, API.NotificationFilter.Request api_req);
	public signal void accepted (Request req, API.NotificationFilter.Request api_req);
	public Gtk.Box btns_box;

	API.NotificationFilter.Request request;
	public NotificationRequest (API.NotificationFilter.Request request) {
		this.request = request;

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
			hexpand = true,
			margin_top = 8,
			margin_bottom = 8,
			margin_start = 12,
			margin_end = 12,
		};

		var name_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
			vexpand = true,
			valign = Gtk.Align.CENTER
		};

		var name = new RichLabel () {
			vexpand = true,
			use_markup = false,
			smaller_emoji_pixel_size = true
		};
		name.instance_emojis = request.account.emojis_map;
		name.label = request.account.display_name;
		name_box.append (name);

		name_box.append (new Gtk.Label (request.account.handle) {
			single_line_mode = true,
			xalign = 0.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			css_classes = {"body", "dim-label"},
			valign = Gtk.Align.CENTER
		});

		box.append (new Widgets.Avatar () {
			account = request.account,
			can_focus = false,
		});
		box.append (name_box);
		box.append (new Gtk.Label (request.notifications_count) {
			valign = Gtk.Align.CENTER,
			css_classes = {"notification-badge"}
		});

		var dismiss_btn = new Gtk.Button () {
			icon_name = "user-trash-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { "flat", "circular", "error" },
			tooltip_text = _("Dismiss")
		};
		dismiss_btn.clicked.connect (on_dismiss);

		var accept_btn = new Gtk.Button () {
			icon_name = "tuba-check-round-outline-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { "flat", "circular", "success" },
			tooltip_text = _("Accept")
		};
		accept_btn.clicked.connect (on_accept);

		btns_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			hexpand = true,
			halign = Gtk.Align.END
		};
		btns_box.append (dismiss_btn);
		btns_box.append (accept_btn);
		box.append (btns_box);

		this.child = box;
	}

	public void on_dismiss () {
		dismissed (new Request.POST (@"/api/v1/notifications/requests/$(request.id)/dismiss").with_account (accounts.active), request);
	}

	public void on_accept () {
		accepted (new Request.POST (@"/api/v1/notifications/requests/$(request.id)/accept").with_account (accounts.active), request);
	}

	public void open () {
		app.main_window.open_view (new Views.NotificationRequestsList (request.account.id, request.account.handle, this));
	}
}
