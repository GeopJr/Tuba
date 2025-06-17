public class Tuba.Dialogs.Components.Editor : Widgets.SandwichSourceView {
	public signal void ctrl_return_pressed (); // TODO
	public signal void toast (Adw.Toast toast);

	private string _locale = "en";
	public string locale {
		get { return _locale; }
		set {
			if (_locale != value) {
				_locale = value;
				count_chars ();
				update_spelling_lang ();
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
		int64 res = 0;

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
		if (new_bottom_child != null && new_bottom_child is Components.Attachable) {
			connect_child_attachable (new_bottom_child as Components.Attachable);
			new_bottom_child.margin_top = 28;
			new_bottom_child.add_css_class ("editor-component");
		}

		base.add_bottom_child (new_bottom_child);
	}

	private void connect_child_attachable (Components.Attachable attachable) {
		attachable.scroll.connect (scroll_request);
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
		// TODO: get rid of lambda
		keypress_controller.key_pressed.connect ((keyval, _, modifier) => {
			modifier &= Gdk.MODIFIER_MASK;
			if ((keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter) && (modifier == Gdk.ModifierType.CONTROL_MASK || modifier == (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.LOCK_MASK))) {
				ctrl_return_pressed ();
				return true;
			}
			return false;
		});
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

	// https://gitlab.gnome.org/GNOME/gtk/-/merge_requests/8477
	// I don't think it will be backported to 4.18, so this is a
	// HACK: queue allocate the placeholder's parent
	// 		 (textviewchild) so it stays in place while scrolling.
	// NOTE: doesn't seem to work all the time, a full resize is
	//		 needed
	#if !GTK_4_19_1
		public override void size_allocate (int width, int height, int baseline) {
			base.size_allocate (width, height, baseline);
			if (placeholder.visible) placeholder.get_parent ().queue_allocate ();
		}
	#endif

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

		if (orientation == HORIZONTAL) natural = 423;
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
