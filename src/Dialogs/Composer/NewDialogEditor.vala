public class Tuba.Dialogs.Componenets.Editor : Adw.Bin {
	public int64 char_count { get; private set; default = 0; }
	public string content {
		owned get {
			return editor.buffer.text;
		}
		set {
			editor.buffer.text = value;
		}
	}

	public void insert_string_at_cursor (string text) {
		editor.buffer.insert_at_cursor (text, text.data.length);
	}

	protected Gtk.Overlay overlay;
	protected Gtk.Label placeholder;
	protected GtkSource.View editor;

	private void count_chars () {
		int64 res = 0;

		//  if (cw_button.active)
		//  	res += (int64) cw_entry.buffer.length;
		res += editor.buffer.get_char_count ();

		char_count = res;
	}

	private void on_content_changed () {
		editor.show_completion ();
		count_chars ();
		placeholder.visible = char_count == 0;
	}

	construct {
		install_editor ();
		install_overlay ();

		child = overlay;
	}

	private void install_editor () {
		editor = new GtkSource.View () {
			vexpand = true,
			hexpand = true,
			top_margin = 6,
			right_margin = 6,
			bottom_margin = 6,
			left_margin = 6,
			pixels_below_lines = 6,
			accepts_tab = false,
			wrap_mode = Gtk.WrapMode.WORD_CHAR,
			tab_width = 1,
			// TODO: remove when other componenets are enabled
			height_request = 100
		};
		editor.remove_css_class ("view");
		editor.add_css_class ("font-large");

		#if LIBSPELLING
			var adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) editor.buffer, Spelling.Checker.get_default ());

			editor.extra_menu = adapter.get_menu_model ();
			editor.insert_action_group ("spelling", adapter);
			adapter.enabled = true;
		#endif

		editor.completion.add_provider (new Tuba.HandleProvider ());
		editor.completion.add_provider (new Tuba.HashtagProvider ());
		editor.completion.add_provider (new Tuba.EmojiProvider ());
		editor.completion.select_on_show = true;
		editor.completion.show_icons = true;
		editor.completion.page_size = 3;
		update_editor_style_scheme ();

		editor.buffer.changed.connect (on_content_changed);
	}

	protected void update_editor_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		var scheme = manager.get_scheme ("adwaita");
		var buffer = editor.buffer as GtkSource.Buffer;
		buffer.style_scheme = scheme;
	}

	private void install_overlay () {
		overlay = new Gtk.Overlay ();
		placeholder = new Gtk.Label (_("What's on your mind?")) {
			valign = Gtk.Align.START,
			halign = Gtk.Align.START,
			justify = Gtk.Justification.FILL,
			margin_top = 6,
			margin_start = 6,
			wrap = true,
			sensitive = false,
			css_classes = {"font-large"}
		};

		overlay.add_overlay (placeholder);
		overlay.child = editor;
	}
}
