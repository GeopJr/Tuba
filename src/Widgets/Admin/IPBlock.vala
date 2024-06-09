public class Tuba.Widgets.Admin.IPBlock : Adw.ActionRow {
	public signal void removed (string ip_block_id);

	~IPBlock () {
		debug ("Destroying IPBlock");
	}

	string ip_block_id;
	public IPBlock (API.Admin.IPBlock ip_block) {
		ip_block_id = ip_block.id;
		this.title = ip_block.ip;

		string sub = API.Admin.IPBlock.Severity.from_string (ip_block.severity).to_string ();
		if (ip_block.comment != "") sub += @" · $(ip_block.comment)";
		this.subtitle = sub;

		var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			css_classes = { "circular", "flat", "error" },
			tooltip_text = _("Delete"),
			valign = Gtk.Align.CENTER
		};
		delete_button.clicked.connect (on_remove);
		this.add_suffix (delete_button);
	}

	public void on_remove () {
		removed (ip_block_id);
	}
}
