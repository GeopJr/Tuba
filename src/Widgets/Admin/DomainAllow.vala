public class Tuba.Widgets.Admin.DomainAllow : Adw.ActionRow {
	public signal void removed (string domain_allow_id);

	~DomainAllow () {
		debug ("Destroying DomainAllow");
	}

	string domain_allow_id;
	public DomainAllow (API.Admin.DomainAllow domain_allow) {
		domain_allow_id = domain_allow.id;
		this.title = domain_allow.domain;

		var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			css_classes = { "circular", "flat", "error" },
			tooltip_text = _("Delete"),
			valign = Gtk.Align.CENTER
		};
		delete_button.clicked.connect (on_remove);
		this.add_suffix (delete_button);
	}

	public void on_remove () {
		removed (domain_allow_id);
	}
}
