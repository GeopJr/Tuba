public class Tuba.Dialogs.Components.Editor : GtkSource.View {
	public int64 char_count { get; private set; default = 0; }
	public string content {
		owned get {
			return this.buffer.text;
		}
		set {
			this.buffer.text = value;
		}
	}

	public void insert_string_at_cursor (string text) {
		this.buffer.insert_at_cursor (text, text.data.length);
	}

	protected Gtk.Label status_title;
	protected Gtk.Label placeholder;
	private void count_chars () {
		int64 res = 0;

		//  if (cw_button.active)
		//  	res += (int64) cw_entry.buffer.length;
		res += this.buffer.get_char_count ();

		char_count = res;
	}

	private void on_content_changed () {
		this.show_completion ();
		count_chars ();
		placeholder.visible = char_count == 0;
	}

	construct {
		this.vexpand = true;
		this.hexpand = true;
		this.top_margin = 6;
		this.right_margin = 6;
		this.bottom_margin = 6;
		this.left_margin = 6;
		this.pixels_below_lines = 6;
		this.accepts_tab = false;
		this.wrap_mode = Gtk.WrapMode.WORD_CHAR;
		this.tab_width = 1;
		// TODO: remove when other componenets are enabled
		this.height_request = 100;

		this.remove_css_class ("view");
		this.add_css_class ("font-large");

		#if LIBSPELLING
			var adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) this.buffer, Spelling.Checker.get_default ());

			this.extra_menu = adapter.get_menu_model ();
			this.insert_action_group ("spelling", adapter);
			adapter.enabled = true;
		#endif

		this.completion.add_provider (new Tuba.HandleProvider ());
		this.completion.add_provider (new Tuba.HashtagProvider ());
		this.completion.add_provider (new Tuba.EmojiProvider ());
		this.completion.select_on_show = true;
		this.completion.show_icons = true;
		this.completion.page_size = 3;
		update_editor_style_scheme ();
		this.buffer.changed.connect (on_content_changed);

		//  status_title = new Gtk.Label (_("New Post")) {
		//  	valign = Gtk.Align.START,
		//  	halign = Gtk.Align.START,
		//  	justify = Gtk.Justification.FILL,
		//  	//  margin_top = 6,
		//  	margin_start = 6,
		//  	wrap = true,
		//  	wrap_mode = Pango.WrapMode.WORD_CHAR,
		//  	justify = Gtk.Justification.CENTER,
		//  	css_classes = {"title-1"}
		//  };
		//  this.add_overlay (status_title, 0, 0);

		placeholder = new Gtk.Label (_("What's on your mind?")) {
			valign = Gtk.Align.START,
			halign = Gtk.Align.START,
			justify = Gtk.Justification.FILL,
			//  margin_top = 6,
			margin_start = 6,
			//  wrap = true,
			sensitive = false,
			css_classes = {"font-large"}
		};
		this.add_overlay (placeholder, 0, 0);
	}

	protected void update_editor_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		var scheme = manager.get_scheme ("adwaita");
		var buffer = this.buffer as GtkSource.Buffer;
		buffer.style_scheme = scheme;
	}

	//  private void install_overlay () {
	//  	overlay = new Gtk.Overlay ();
	//  	placeholder = new Gtk.Label (_("What's on your mind?")) {
	//  		valign = Gtk.Align.START,
	//  		halign = Gtk.Align.START,
	//  		justify = Gtk.Justification.FILL,
	//  		margin_top = 6,
	//  		margin_start = 6,
	//  		wrap = true,
	//  		sensitive = false,
	//  		css_classes = {"font-large"}
	//  	};

	//  	overlay.add_overlay (placeholder);
	//  	overlay.child = editor;
	//  }
}
