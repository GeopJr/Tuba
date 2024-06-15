public class Tuba.Widgets.Admin.DomainBlock : Adw.ExpanderRow {
	public signal void removed (string federation_block_id);

	~DomainBlock () {
		debug ("Destroying DomainBlock");
	}

	string federation_block_id;
	public DomainBlock (API.Admin.DomainBlock federation_block) {
		federation_block_id = federation_block.id;
		this.overflow = Gtk.Overflow.HIDDEN;
		this.title = federation_block.domain;
		this.subtitle = API.Admin.DomainBlock.Severity.from_string (federation_block.severity).to_string ();

		add_expander_row_label (
			"<b>%s</b>: %s".printf (
				_("Private Comment"),
				federation_block.private_comment == null || federation_block.private_comment == "" ? _("None") : federation_block.private_comment
			)
		);

		add_expander_row_label (
			"<b>%s</b>: %s".printf (
				_("Public Comment"),
				federation_block.public_comment == null || federation_block.public_comment == "" ? _("None") : federation_block.public_comment
			)
		);

		string[] rules = {};
		if (federation_block.reject_media) rules += _("Reject Media Files");
		if (federation_block.reject_reports) rules += _("Reject Reports");
		if (federation_block.obfuscate) rules += _("Obfuscate Domain Name");

		if (rules.length > 0) {
			add_expander_row_label ("<b>%s</b>".printf (string.joinv ("·", rules)));
		}

		var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			css_classes = { "circular", "flat", "error" },
			tooltip_text = _("Delete"),
			valign = Gtk.Align.CENTER
		};
		delete_button.clicked.connect (on_remove);
		this.add_suffix (delete_button);
	}

	private void add_expander_row_label (string label) {
		this.add_row (
			new Gtk.Label (label) {
				wrap = true,
				xalign = 0.0f,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				use_markup = true,
				margin_bottom = 8,
				margin_top = 8,
				margin_start = 8,
				margin_end = 8,
			}
		);
	}

	public void on_remove () {
		removed (federation_block_id);
	}
}
