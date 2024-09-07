public class Tuba.AttachmentsPageAttachment : Widgets.Attachment.Item {
	private class UtilityPanel : Adw.Dialog {
		~UtilityPanel () {
			debug ("Destroying UtilityPanel");
		}

		public signal void saved ();

		protected Adw.ToastOverlay toast_overlay;
		protected Adw.HeaderBar headerbar;
		protected Adw.ToolbarView toolbar_view;
		protected Gtk.Button save_btn;

		private bool _working = false;
		public bool working {
			get { return _working; }
			set {
				_working = value;

				save_btn.sensitive = !_working && _can_save;
			}
		}

		private bool _can_save = false;
		public bool can_save {
			get { return _can_save; }
			set {
				_can_save = value;

				save_btn.sensitive = !_working && _can_save;
			}
		}

		construct {
			toast_overlay = new Adw.ToastOverlay () {
				vexpand = true,
				hexpand = true
			};

			this.child = toast_overlay;
			this.content_width = 400;
			this.content_height = 300;

			toolbar_view = new Adw.ToolbarView ();
			headerbar = new Adw.HeaderBar ();

			save_btn = new Gtk.Button.with_label (_("Save"));
			save_btn.add_css_class ("suggested-action");
			headerbar.pack_end (save_btn);

			toolbar_view.add_top_bar (headerbar);

			toast_overlay.child = toolbar_view;
		}

		public void show_toast (string text) {
			toast_overlay.add_toast (new Adw.Toast (text) {
				timeout = 5
			});
		}

		public void on_error (string text) {
			this.working = false;
			show_toast (text);
		}
	}

	private class AltTextDialog : UtilityPanel {
		~AltTextDialog () {
			debug ("Destroying AltTextDialog");
		}

		const int ALT_MAX_CHARS = 1500;
		GtkSource.View alt_editor;
		Gtk.Label dialog_char_counter;

		public string get_alt_text () {
			return alt_editor.buffer.text;
		}

		public int get_char_count () {
			return alt_editor.buffer.get_char_count ();
		}

		construct {
			this.title = _("Alternative text for attachment");

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
				vexpand = true,
				child = alt_editor
			};

			var bottom_bar = new Gtk.ActionBar ();
			dialog_char_counter = new Gtk.Label ("") {
				margin_end = 6,
				margin_top = 14,
				margin_bottom = 14,
				tooltip_text = _("Characters Left"),
				css_classes = { "heading" }
			};
			bottom_bar.pack_end (dialog_char_counter);

			toolbar_view.set_content (scroller);
			toolbar_view.add_bottom_bar (bottom_bar);

			alt_editor.buffer.changed.connect (on_alt_editor_buffer_change);
			save_btn.clicked.connect (on_save);
		}

		protected void update_style_scheme () {
			var manager = GtkSource.StyleSchemeManager.get_default ();
			string scheme_name = "Adwaita";
			if (Adw.StyleManager.get_default ().dark) scheme_name += "-dark";
			((GtkSource.Buffer) alt_editor.buffer).style_scheme = manager.get_scheme (scheme_name);
		}

		private void on_save () {
			this.working = true;
			saved ();
		}

		public AltTextDialog (string alt_text) {
			dialog_char_counter.label = remaining_alt_chars (alt_text != null ? alt_text.length : 0);

			if (alt_text != null) {
				this.can_save = validate (alt_text.length);
				alt_editor.buffer.text = alt_text;
			} else {
				this.can_save = false;
			}
		}

		public static bool validate (int text_size) {
			return text_size <= ALT_MAX_CHARS;
		}

		private void on_alt_editor_buffer_change () {
			var t_val = validate (alt_editor.buffer.get_char_count ());
			this.can_save = t_val;
			dialog_char_counter.label = remaining_alt_chars (alt_editor.buffer.get_char_count ());
			if (t_val) {
				dialog_char_counter.remove_css_class ("error");
			} else {
				dialog_char_counter.add_css_class ("error");
			}
		}

		protected string remaining_alt_chars (int text_size) {
			return (ALT_MAX_CHARS - text_size).to_string ();
		}
	}

	private class FocusPickerDialog : UtilityPanel {
		~FocusPickerDialog () {
			debug ("Destroying FocusPickerDialog");
		}

		public float pos_x { get; set; default = 0.0f; }
		public float pos_y { get; set; default = 0.0f; }

		construct {
			this.title = _("Focal point for attachment thumbnail");
			save_btn.clicked.connect (on_save);
		}

		private void on_save () {
			this.working = true;
			saved ();
		}

		public FocusPickerDialog (Gdk.Paintable paintable, float pos_x, float pos_y) {
			this.pos_x = pos_x;
			this.pos_y = pos_y;

			var focus_picker = new Widgets.FocusPicker (paintable) {
				pos_x = pos_x,
				pos_y = pos_y
			};
			focus_picker.bind_property ("pos-x", this, "pos-x", GLib.BindingFlags.SYNC_CREATE);
			focus_picker.bind_property ("pos-y", this, "pos-y", GLib.BindingFlags.SYNC_CREATE);

			toolbar_view.content = focus_picker;
		}
	}

	public string? alt_text { get; private set; default = null; }
	public float pos_x { get; set; default = 0.0f; }
	public float pos_y { get; set; default = 0.0f; }

	protected Gtk.Picture pic;
	protected File? attachment_file;
	private unowned Dialogs.Compose compose_dialog;
	protected string id;
	private bool edit_mode = false;

	~AttachmentsPageAttachment () {
		close_dialogs ();
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

		if (t_entity.meta != null && t_entity.meta.focus != null) {
			this.pos_x = t_entity.meta.focus.x;
			this.pos_y = t_entity.meta.focus.y;
		}

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
			Tuba.Helper.Image.request_paintable (t_entity.preview_url, null, false, on_cache_response);
		}
		button.child = pic;

		alt_btn.tooltip_text = _("Edit Alt Text");
		alt_btn.disconnect (alt_btn_clicked_id);
		alt_btn.clicked.connect (on_alt_btn_clicked);
		alt_btn.add_css_class ("error");
		alt_btn.remove_css_class ("flat");

		var delete_button = new Gtk.Button () {
			icon_name = "user-trash-symbolic",
			valign = Gtk.Align.END,
			halign = Gtk.Align.END,
			hexpand = true,
			tooltip_text = _("Remove Attachment"),
			css_classes = { "error", "ttl-status-badge" }
		};

		overlay.add_overlay (delete_button);
		delete_button.clicked.connect (on_delete_clicked);

		var focus_button = new Gtk.Button.with_label ("Focus Point TEST") {
			valign = Gtk.Align.START,
			halign = Gtk.Align.END,
		};
		overlay.add_overlay (focus_button);
		focus_button.clicked.connect (on_focus_picker_clicked);

		alt_text = t_entity.description ?? "";
		update_alt_css (alt_text.length);
	}

	FocusPickerDialog? focus_picker_dialog = null;
	private void on_focus_picker_clicked () {
		if (focus_picker_dialog == null) {
			focus_picker_dialog = new FocusPickerDialog (pic.paintable, pos_x, pos_y);
			focus_picker_dialog.saved.connect (on_save_clicked);
		}

		focus_picker_dialog.present (compose_dialog);
	}

	AltTextDialog? alt_text_dialog = null;
	private void on_alt_btn_clicked () {
		if (alt_text_dialog == null) {
			alt_text_dialog = new AltTextDialog (alt_text);
			alt_text_dialog.saved.connect (on_save_clicked);
		}

		alt_text_dialog.present (compose_dialog);
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

	private void on_save_clicked () {
		if (alt_text_dialog != null) {
			this.alt_text = alt_text_dialog.get_alt_text ();
			update_alt_css (alt_text_dialog.get_char_count ());
		}

		if (focus_picker_dialog != null) {
			this.pos_x = focus_picker_dialog.pos_x;
			this.pos_y = focus_picker_dialog.pos_y;
		}

		if (!edit_mode) {
			new Request.PUT (@"/api/v1/media/$(id)")
				.with_account (accounts.active)
				.with_param ("description", alt_text)
				.with_param ("focus", "%.2f,%.2f".printf (pos_x, pos_y))
				.then (() => {
					close_dialogs ();
				})
				.on_error ((code, message) => {
					string error_text = @"$code $message";

					if (alt_text_dialog != null) alt_text_dialog.on_error (error_text);
					if (focus_picker_dialog != null) focus_picker_dialog.on_error (error_text);
				})
				.exec ();
		} else {
			close_dialogs ();
		}
	}

	private void close_dialogs () {
		if (alt_text_dialog != null) {
			alt_text_dialog.force_close ();
			alt_text_dialog = null;
		}

		if (focus_picker_dialog != null) {
			focus_picker_dialog.force_close ();
			focus_picker_dialog = null;
		}
	}

	private void update_alt_css (int text_length) {
		if (AltTextDialog.validate (text_length) && text_length > 0) {
			alt_btn.add_css_class ("success");
			alt_btn.remove_css_class ("error");
		} else {
			alt_btn.remove_css_class ("success");
			alt_btn.add_css_class ("error");
		}
	}
}
