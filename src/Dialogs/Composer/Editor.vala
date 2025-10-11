public class Tuba.Dialogs.Composer.Components.Editor : Widgets.SandwichSourceView, Composer.Components.Attachable {
	public bool edit_mode { get; set; default = false; }
	public signal void ctrl_return_pressed ();

	~Editor () {
		debug ("Destroying Composer Editor");
	}

	private string _locale = "en";
	public string locale {
		get { return _locale; }
		set {
			if (_locale != value) {
				_locale = value;
				count_chars ();
				#if LIBSPELLING
					update_spelling_lang ();
				#endif
			}
		}
	}

	private string _content_type = "fedi-basic";
	public string content_type {
		get { return _content_type; }
		set {
			if (_content_type != value) {
				_content_type = value;
				update_language_highlight ();
			}
		}
	}

	static construct {
		set_accessible_role (Gtk.AccessibleRole.GROUP);
	}

	// TextView's overlay children have weird
	// measuring that messes with our clamp.
	// Since we only need it for the placeholder
	// which is a label that should be liberal
	// since other languages can have longer
	// text and since it cannot wrap, it should
	// have a big enough h nat while h min is 0
	public class PlaceholderHack : Gtk.Widget {
		~PlaceholderHack () {
			debug ("Destroying Composer PlaceholderHack");
		}

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

	#if LIBSPELLING
		private void update_spelling_lang () {
			var new_locale = original_libspelling_lang_iso639 == this.locale
				? original_libspelling_lang
				: this.locale;

			var checker = Spelling.Checker.get_default ();
			checker.language = new_locale;

			string? new_lang = checker.language;
			if (new_lang == null && original_libspelling_lang != null) {
				checker.language = original_libspelling_lang;
			}
		}
	#endif

	protected Gtk.Label status_title;
	protected PlaceholderHack placeholder;
	private void count_chars () {
		string replaced_urls = Utils.Tracking.cleanup_content_with_uris (
			this.buffer.text,
			Utils.Tracking.extract_uris (this.buffer.text),
			Utils.Tracking.CleanupType.SPECIFIC_LENGTH,
			accounts.active.instance_info.compat_status_characters_reserved_per_url
		);
		string replaced_mentions = Utils.Counting.replace_mentions (replaced_urls);

		this.char_count = Utils.Counting.chars (replaced_mentions, this.locale);
	}

	private void on_content_changed () {
		this.show_completion ();
		count_chars ();
		placeholder.visible = char_count == 0;
	}

	public override void add_bottom_child (Gtk.Widget? new_bottom_child) {
		if (is_bottom_child (new_bottom_child)) return;

		base.add_bottom_child (new_bottom_child);
		if (new_bottom_child != null) scroll_to_widget (true);
	}

	private void connect_child_attachable (Composer.Components.Attachable attachable) {
		attachable.scroll.connect (scroll_request);
		attachable.toast.connect (toast_request);
		attachable.push_subpage.connect (push_subpage_request);
		attachable.pop_subpage.connect (pop_request);
		attachable.edit_mode = this.edit_mode;
	}

	private void disconnect_child_attachable (Composer.Components.Attachable attachable) {
		attachable.scroll.disconnect (scroll_request);
		attachable.toast.disconnect (toast_request);
		attachable.push_subpage.disconnect (push_subpage_request);
		attachable.pop_subpage.disconnect (pop_request);
	}

	protected override void clear_child_widget (Gtk.Widget widget) {
		if (widget is Composer.Components.Attachable) disconnect_child_attachable (widget as Composer.Components.Attachable);
		base.clear_child_widget (widget);
	}

	protected override void setup_child_widget (Gtk.Widget widget) {
		if (widget is Composer.Components.Attachable) {
			connect_child_attachable (widget as Composer.Components.Attachable);
			widget.add_css_class ("editor-component");
			widget.margin_top = 28;
		}
		base.setup_child_widget (widget);
	}

	#if LIBSPELLING
		protected Spelling.TextBufferAdapter adapter;
		private void update_spelling_settings () {
			settings.spellchecker_enabled = adapter.enabled;
		}

		string? original_libspelling_lang = null;
		string? original_libspelling_lang_iso639 = null;
	#endif

	GtkSource.LanguageManager lang_manager;
	Gtk.Box status_box;
	construct {
		lang_manager = new GtkSource.LanguageManager ();

		this.overflow = VISIBLE;
		this.vexpand = true;
		this.hexpand = true;
		this.right_margin = 6;
		this.left_margin = 6;
		this.accepts_tab = false;
		this.wrap_mode = Gtk.WrapMode.WORD_CHAR;
		this.tab_width = 1;
		this.input_hints = WORD_COMPLETION | SPELLCHECK | EMOJI;

		this.remove_css_class ("view");
		this.add_css_class ("font-large");
		this.add_css_class ("reset");

		#if LIBSPELLING
			adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) this.buffer, Spelling.Checker.get_default ());
			original_libspelling_lang = Spelling.Checker.get_default ().language;
			if (original_libspelling_lang != null) original_libspelling_lang_iso639 = original_libspelling_lang.split_set ("-_", 2)[0];

			this.extra_menu = adapter.get_menu_model ();
			this.insert_action_group ("spelling", adapter);

			adapter.enabled = settings.spellchecker_enabled;
			adapter.notify["enabled"].connect (update_spelling_settings);
		#endif

		var keypress_controller = new Gtk.EventControllerKey ();
		keypress_controller.key_pressed.connect (on_keypress);
		this.add_controller (keypress_controller);

		this.completion.add_provider (new Tuba.HandleProvider ());
		this.completion.add_provider (new Tuba.HashtagProvider ());
		this.completion.add_provider (new Tuba.EmojiProvider ());
		this.completion.select_on_show = true;
		this.completion.show_icons = true;
		this.completion.page_size = 3;
		((GtkSource.Buffer) this.buffer).highlight_matching_brackets = true;
		((GtkSource.Buffer) this.buffer).highlight_syntax = true;

		var adw_manager = Adw.StyleManager.get_default ();
		adw_manager.notify["dark"].connect (update_style_scheme);
		adw_manager.notify["accent-color-rgba"].connect (update_style_scheme);
		update_style_scheme ();
		update_language_highlight ();

		this.buffer.paste_done.connect (on_paste);
		this.buffer.changed.connect (on_content_changed);

		status_box = new Gtk.Box (VERTICAL, 30) {
			valign = START,
			vexpand = true,
			margin_bottom = 28,
			css_classes = { "background-none" }
		};

		status_title = new Gtk.Label (_("New Post")) {
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			css_classes = {"title-2"},
			justify = CENTER,
			ellipsize = END,
			lines = 3,
			// this label is synced with the dialog title,
			// screen readers end up reading it twice,
			// let's hide this
			accessible_role = PRESENTATION
		};

		status_box.append (status_title);
		this.add_top_child (status_box);

		// translators: composer placeholder
		placeholder = new PlaceholderHack (new Gtk.Label (_("What's on your mind?")) {
			valign = Gtk.Align.START,
			halign = Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL ? Gtk.Align.END : Gtk.Align.START,
			justify = Gtk.Justification.FILL,
			//  margin_top = 6,
			margin_start = 8,
			margin_end = 8,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			sensitive = false,
			css_classes = {"font-large"}
		});
		this.add_overlay (placeholder, 0, 0);
		this.update_property (Gtk.AccessibleProperty.PLACEHOLDER, _("What's on your mind?"), -1);

		unowned Gtk.Widget? view_child = placeholder.get_parent ();
		if (view_child != null) view_child.can_target = view_child.can_focus = false;
	}

	public void set_title (string label, Gtk.Widget? sub_widget = null) {
		if (status_title.label != label) status_title.label = label;
		if (sub_widget != null) status_box.append (sub_widget);
	}

	private bool on_keypress (uint keyval, uint keycode, Gdk.ModifierType modifier) {
		modifier &= Gdk.MODIFIER_MASK;
		if ((keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter) && (modifier == Gdk.ModifierType.CONTROL_MASK || modifier == (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.LOCK_MASK))) {
			ctrl_return_pressed ();
			return true;
		}
		return false;
	}

	protected void update_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		var adw_manager = Adw.StyleManager.get_default ();

		string scheme_name = "Fedi";
		if (adw_manager.get_system_supports_accent_colors ()) {
			switch (adw_manager.get_accent_color ()) {
				case Adw.AccentColor.YELLOW:
					scheme_name += "-yellow";
					break;
				case Adw.AccentColor.TEAL:
					scheme_name += "-teal";
					break;
				case Adw.AccentColor.PURPLE:
					scheme_name += "-purple";
					break;
				case Adw.AccentColor.RED:
					scheme_name += "-red";
					break;
				case Adw.AccentColor.GREEN:
					scheme_name += "-green";
					break;
				case Adw.AccentColor.ORANGE:
					scheme_name += "-orange";
					break;
				case Adw.AccentColor.SLATE:
					scheme_name += "-slate";
					break;
				case Adw.AccentColor.PINK:
					scheme_name += "-pink";
					break;
				default:
					scheme_name += "-blue";
					break;
			}
		} else {
			scheme_name += "-blue";
		}

		if (adw_manager.dark) scheme_name += "-dark";
		((GtkSource.Buffer) this.buffer).style_scheme = manager.get_scheme (scheme_name);
	}

	protected void update_language_highlight () {
		((GtkSource.Buffer) this.buffer).set_language (lang_manager.get_language (this.content_type));
	}

	public void scroll_request (bool bottom = false) {
		this.scroll_animated (bottom);
	}

	public void toast_request (Adw.Toast toast_obj) {
		toast (toast_obj);
	}

	public void push_subpage_request (Adw.NavigationPage page) {
		push_subpage (page);
	}

	public void pop_request () {
		pop_subpage ();
	}

	// HACK: we need the default dialog size to be wider
	//		 but still follow the content, so let's set
	//		 the nat width to this
	public override void measure (
		Gtk.Orientation orientation,
		int for_size,
		out int minimum,
		out int natural,
		out int minimum_baseline,
		out int natural_baseline
	) {
		base.measure (
			orientation,
			for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);
		natural = int.max (minimum, orientation == HORIZONTAL ? 423 : int.max (natural, 300));
	}

	public void set_cursor_at_start () {
		Gtk.TextIter star_iter;
		this.buffer.get_start_iter (out star_iter);
		this.buffer.place_cursor (star_iter);
	}

	protected void on_paste (Gdk.Clipboard clp) {
		if (!settings.strip_tracking) return;
		var clean_buffer = Utils.Tracking.cleanup_content_with_uris (
			this.buffer.text,
			Utils.Tracking.extract_uris (this.buffer.text),
			Utils.Tracking.CleanupType.STRIP_TRACKING
		);
		if (clean_buffer == this.buffer.text) return;

		Gtk.TextIter start_iter;
		Gtk.TextIter end_iter;
		this.buffer.get_bounds (out start_iter, out end_iter);
		this.buffer.begin_user_action ();
		this.buffer.delete (ref start_iter, ref end_iter);
		this.buffer.insert (ref start_iter, clean_buffer, -1);
		this.buffer.end_user_action ();

		var toast_obj = new Adw.Toast (
			// translators: "Stripped" is a past tense verb in this context, not an adjective.
			_("Stripped tracking parameters")
		) {
			timeout = 3,
			button_label = _("Undo")
		};
		toast_obj.button_clicked.connect (undo);
		toast (toast_obj);
	}

	private void undo () {
		this.buffer.undo ();
	}
}
