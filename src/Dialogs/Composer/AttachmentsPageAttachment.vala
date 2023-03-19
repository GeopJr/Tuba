public class Tooth.AttachmentsPageAttachment : Widgets.Attachment.Item {

	protected Gtk.Picture pic;
	protected File attachment_file;
	protected string? alt_text { get; set; default = null; }
	private const int ALT_MAX_CHARS = 1500;
	private Dialogs.Compose compose_dialog;
	protected string id;

    public AttachmentsPageAttachment (string attachment_id, File file, Dialogs.Compose dialog){
		id = attachment_id;
		attachment_file = file;
		compose_dialog = dialog;
		pic = new Gtk.Picture.for_file (file) {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true
		};
		button.child = pic;
		alt_btn.tooltip_text = _("Edit Alt Text");
		alt_btn.disconnect(alt_btn_clicked_id);
		alt_btn.clicked.connect(() => {
			create_alt_text_input_window().show();
		});
		alt_btn.add_css_class("error");
		alt_btn.remove_css_class("flat");

		var delete_button = new Gtk.Button() {
			icon_name = "tooth-trash-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Remove Attachment")
		};
		badge_box.append(delete_button);
		delete_button.add_css_class("error");

		delete_button.clicked.connect(() => remove_from_model());
	}

	public virtual signal void remove_from_model () {}

	protected override void on_rebind () {}

	protected override void on_secondary_click () {}

	protected override void on_click () {
		Host.open_uri (attachment_file.get_path ());
	}

	protected bool validate(int text_size) {
		// text_size > 0 &&
		return text_size <= ALT_MAX_CHARS;
	}

	protected string remaining_alt_chars(int text_size) {
		return (ALT_MAX_CHARS - text_size).to_string();
	}

	protected Adw.Window create_alt_text_input_window () {
		var alt_editor = new Gtk.TextView () {
			vexpand = true,
			hexpand = true,
			top_margin = 6,
			right_margin = 6,
			bottom_margin = 6,
			left_margin = 6,
			pixels_below_lines = 6,
			accepts_tab = false,
			wrap_mode = Gtk.WrapMode.WORD_CHAR
		};
		var scroller = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true
		};
		scroller.child = alt_editor;

		var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
		var headerbar = new Adw.HeaderBar();

		var bottom_bar = new Gtk.ActionBar ();
		var char_counter = new Gtk.Label (remaining_alt_chars(alt_text != null ? alt_text.length : 0)) {
			margin_end = 6,
			margin_top = 14,
			margin_bottom = 14,
			tooltip_text = _("Characters Left")
		};
		char_counter.add_css_class ("heading");
		bottom_bar.pack_end (char_counter);

		var save_btn = new Gtk.Button.with_label(_("Save"));
		save_btn.add_css_class("suggested-action");

		save_btn.sensitive = alt_text != null && validate(alt_text.length);

		headerbar.pack_end(save_btn);

		box.append(headerbar);
		box.append(scroller);
		box.append(bottom_bar);

		if (alt_text != null)
			alt_editor.buffer.text = alt_text;
		alt_editor.buffer.changed.connect (() => {
			var t_val = validate(alt_editor.buffer.get_char_count ());
			save_btn.sensitive = t_val;
			char_counter.label = remaining_alt_chars(alt_editor.buffer.get_char_count ());
			if (t_val) {
				char_counter.remove_css_class ("error");
			} else {
				char_counter.add_css_class ("error");
			}
		});

		var dialog = new Adw.Window() {
			modal = true,
			title = @"Alternative text for attachment",
			transient_for = compose_dialog,
			content = box,
			default_width = 400,
			default_height = 300
		};

		save_btn.clicked.connect(() => {
			alt_text = alt_editor.buffer.text;
			if (validate(alt_editor.buffer.get_char_count ()) && alt_editor.buffer.get_char_count () > 0) {
				alt_btn.add_css_class("success");
				alt_btn.remove_css_class("error");
			} else {
				alt_btn.remove_css_class("success");
				alt_btn.add_css_class("error");
			}
			new Request.PUT (@"/api/v1/media/$(id)")
				.with_account (accounts.active)
				.with_param ("description", HtmlUtils.uri_encode (alt_text))
				.then(() => {})
				.exec ();
			dialog.destroy();
		});

		return dialog;
	}
}
