public class Tuba.AttachmentsPageAttachment : Widgets.Attachment.Item {

	protected Gtk.Picture pic;
	protected File? attachment_file;
	public string? alt_text { get; private set; default = null; }
	private const int ALT_MAX_CHARS = 1500;
	private unowned Dialogs.Compose compose_dialog;
	protected string id;
	private bool edit_mode = false;

	~AttachmentsPageAttachment () {
		close_dialog ();
		debug ("Destroying AttachmentsPageAttachment");
	}

    public AttachmentsPageAttachment (
		string attachment_id,
		File? file,
		Dialogs.Compose dialog,
		API.Attachment? t_entity,
		bool t_edit_mode = false
	) {
		edit_mode = t_edit_mode;
		id = attachment_id;
		attachment_file = file;
		compose_dialog = dialog;

		pic = new Gtk.Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true
		};
		if (file != null) {
			pic.file = file;
		} else {
			entity = t_entity;
			Tuba.Helper.Image.request_paintable (t_entity.preview_url, null, on_cache_response);
		}
		button.child = pic;

		alt_btn.tooltip_text = _("Edit Alt Text");
		alt_btn.disconnect (alt_btn_clicked_id);
		alt_btn.clicked.connect (on_alt_btn_clicked);
		alt_btn.add_css_class ("error");
		alt_btn.remove_css_class ("flat");

		var delete_button = new Gtk.Button () {
			icon_name = "user-trash-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.END,
			hexpand = true,
			tooltip_text = _("Remove Attachment"),
			css_classes = { "error" }
		};
		badge_box.append (delete_button);
		badge_box.halign = Gtk.Align.FILL;
		badge_box.add_css_class ("attachmentpageattachment");
		badge_box.remove_css_class ("linked");

		delete_button.clicked.connect (on_delete_clicked);

		alt_text = t_entity.description ?? "";
		update_alt_css (alt_text.length);
	}

	private void on_alt_btn_clicked () {
		create_alt_text_input_dialog ().present (compose_dialog);
	}

	private void on_delete_clicked () {
		remove_from_model ();
	}

	protected virtual void on_cache_response (Gdk.Paintable? data) {
		pic.paintable = data;
	}

	public virtual signal void remove_from_model () {}

	protected override void on_rebind () {}

	protected override void on_secondary_click (int n_press, double x, double y) {}

	protected override void on_click () {
		if (attachment_file != null) {
			Host.open_url (attachment_file.get_path ());
		} else if (entity != null) {
			base.on_click ();
		}
	}

	protected bool validate (int text_size) {
		// text_size > 0 &&
		return text_size <= ALT_MAX_CHARS;
	}

	protected string remaining_alt_chars (int text_size) {
		return (ALT_MAX_CHARS - text_size).to_string ();
	}

	GtkSource.View alt_editor;
	Adw.Dialog dialog;
	Gtk.Button dialog_save_btn;
	Gtk.Label dialog_char_counter;
	protected Adw.Dialog create_alt_text_input_dialog () {
		alt_editor = new GtkSource.View () {
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
		alt_editor.remove_css_class ("view");
		alt_editor.add_css_class ("reset");

		Adw.StyleManager.get_default ().notify["dark"].connect (update_style_scheme);
		update_style_scheme ();

		#if LIBSPELLING
			var adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) alt_editor.buffer, Spelling.Checker.get_default ());

			alt_editor.extra_menu = adapter.get_menu_model ();
			alt_editor.insert_action_group ("spelling", adapter);
			adapter.enabled = true;
		#endif

		var scroller = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true
		};
		scroller.child = alt_editor;

		var toolbar_view = new Adw.ToolbarView ();
		var headerbar = new Adw.HeaderBar () {
			centering_policy = Adw.CenteringPolicy.STRICT
		};

		var bottom_bar = new Gtk.ActionBar ();
		dialog_char_counter = new Gtk.Label (remaining_alt_chars (alt_text != null ? alt_text.length : 0)) {
			margin_end = 6,
			margin_top = 14,
			margin_bottom = 14,
			tooltip_text = _("Characters Left"),
			css_classes = { "heading" }
		};
		bottom_bar.pack_end (dialog_char_counter);

		dialog_save_btn = new Gtk.Button.with_label (_("Save"));
		dialog_save_btn.add_css_class ("suggested-action");
		dialog_save_btn.sensitive = alt_text != null && validate (alt_text.length);
		headerbar.pack_end (dialog_save_btn);

		toolbar_view.add_top_bar (headerbar);
		toolbar_view.set_content (scroller);
		toolbar_view.add_bottom_bar (bottom_bar);

		if (alt_text != null)
			alt_editor.buffer.text = alt_text;
		alt_editor.buffer.changed.connect (on_alt_editor_buffer_change);

		dialog = new Adw.Dialog () {
			title = _("Alternative text for attachment"),
			child = toolbar_view,
			content_width = 400,
			content_height = 300
		};

		dialog_save_btn.clicked.connect (on_save_clicked);

		return dialog;
	}

	protected void update_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		string scheme_name = "Adwaita";
		if (Adw.StyleManager.get_default ().dark) scheme_name += "-dark";
		((GtkSource.Buffer) alt_editor.buffer).style_scheme = manager.get_scheme (scheme_name);
	}

	private void on_save_clicked () {
		alt_text = alt_editor.buffer.text;
		update_alt_css (alt_editor.buffer.get_char_count ());

		if (!edit_mode) {
			new Request.PUT (@"/api/v1/media/$(id)")
				.with_account (accounts.active)
				.with_param ("description", alt_text)
				.exec ();
		}

		close_dialog ();
	}

	private void on_alt_editor_buffer_change () {
		var t_val = validate (alt_editor.buffer.get_char_count ());
		dialog_save_btn.sensitive = t_val;
		dialog_char_counter.label = remaining_alt_chars (alt_editor.buffer.get_char_count ());
		if (t_val) {
			dialog_char_counter.remove_css_class ("error");
		} else {
			dialog_char_counter.add_css_class ("error");
		}
	}

	private void close_dialog () {
		if (dialog != null) {
			dialog.force_close ();
			dialog = null;
			alt_editor = null;
			dialog_save_btn = null;
			dialog_char_counter = null;
		}
	}

	private void update_alt_css (int text_length) {
		if (validate (text_length) && text_length > 0) {
			alt_btn.add_css_class ("success");
			alt_btn.remove_css_class ("error");
		} else {
			alt_btn.remove_css_class ("success");
			alt_btn.add_css_class ("error");
		}
	}
}
