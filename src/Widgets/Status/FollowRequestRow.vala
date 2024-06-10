public class Tuba.Widgets.FollowRequestRow : Gtk.Box {
	public signal void declined (Request req);
	public signal void accepted (Request req);

	public string id { get; set; }

	Gtk.Button decline_fr_button = new Gtk.Button.from_icon_name ("tuba-cross-large-symbolic") {
		tooltip_text = _("Decline"),
		halign = Gtk.Align.CENTER,
		css_classes = { "flat", "circular", "error" }
	};

	Gtk.Button accept_fr_button = new Gtk.Button.from_icon_name ("tuba-check-round-outline-symbolic") {
		tooltip_text = _("Accept"),
		halign = Gtk.Align.CENTER,
		css_classes = { "flat", "circular", "success" }
	};

	construct {
		this.add_css_class ("ttl-post-actions");
		this.spacing = 0;
		this.homogeneous = true;

		this.append (decline_fr_button);
		this.append (accept_fr_button);

		decline_fr_button.clicked.connect (on_decline);
		accept_fr_button.clicked.connect (on_accept);
	}

	void on_decline () {
		declined (new Request.POST (@"/api/v1/follow_requests/$id/reject").with_account (accounts.active));
	}

	void on_accept () {
		accepted (new Request.POST (@"/api/v1/follow_requests/$id/authorize").with_account (accounts.active));
	}

	public FollowRequestRow (string t_id) {
		Object (id: t_id);
	}
}
