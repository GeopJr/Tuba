public class Tuba.Dialogs.Components.Editor : Widgets.SandwichSourceView {
	// TextView's overlay children have weird
	// measuring that messes with our clamp.
	// Since we only need it for the placeholder
	// which is a label that should be liberal
	// since other languages can have longer
	// text and since it cannot wrap, it should
	// have a big enough h nat while h min is 0
	protected class PlaceholderHack : Gtk.Widget {
		static construct {
			set_accessible_role (Gtk.AccessibleRole.PRESENTATION);
		}

		Gtk.Label label;
		public PlaceholderHack (Gtk.Label label) {
			this.label = label;
			label.set_parent (this);
		}

		public override Gtk.SizeRequestMode get_request_mode () {
			return label.get_request_mode ();
		}

		public override void measure (
			Gtk.Orientation orientation,
			int for_size,
			out int minimum,
			out int natural,
			out int minimum_baseline,
			out int natural_baseline
		) {
			this.label.measure (
				orientation,
				for_size,
				out minimum,
				out natural,
				out minimum_baseline,
				out natural_baseline
			);

			if (orientation == HORIZONTAL) natural = int.max (500, minimum);
		}

		public override void size_allocate (int width, int height, int baseline) {
			label.allocate (500, height, baseline, null);
		}

		public override void dispose () {
			label.unparent ();
			label = null;
			base.dispose ();
		}
	}


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
	protected PlaceholderHack placeholder;
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
		this.overflow = VISIBLE;
		this.vexpand = true;
		this.hexpand = true;
		this.right_margin = 6;
		this.left_margin = 6;
		this.accepts_tab = false;
		this.wrap_mode = Gtk.WrapMode.WORD_CHAR;
		this.tab_width = 1;

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

		status_title = new Gtk.Label (_("New Post")) {
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			css_classes = {"title-2"},
			margin_bottom = 28
		};
		this.add_top_child (status_title);

		// translators: composer placeholder
		placeholder = new PlaceholderHack (new Gtk.Label (_("What's on your mind?")) {
			valign = Gtk.Align.START,
			halign = Gtk.Align.START,
			justify = Gtk.Justification.FILL,
			//  margin_top = 6,
			margin_start = 8,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			sensitive = false,
			css_classes = {"font-large"}
		});
		this.add_overlay (placeholder, 0, 0);

		unowned Gtk.Widget? view_child = placeholder.get_parent ();
		if (view_child != null) view_child.can_target = view_child.can_focus = false;
	}

	protected void update_editor_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		var scheme = manager.get_scheme ("adwaita");
		var buffer = this.buffer as GtkSource.Buffer;
		buffer.style_scheme = scheme;
	}

	public void scroll_request (bool bottom = false) {
		this.scroll_animated (bottom);
	}

	// https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/8477
	// I don't think it will be backported to 4.18, so this is a
	// HACK: queue allocate the placeholder's parent
	// 		 (textviewchild) so it stays in place while scrolling.
	#if !GTK_4_19_1
		public override void size_allocate (int width, int height, int baseline) {
			base.size_allocate (width, height, baseline);
			if (placeholder.visible) placeholder.get_parent ().queue_allocate ();
		}
	#endif
}
