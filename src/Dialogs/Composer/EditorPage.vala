using Gtk;

public class Tuba.EditorPage : ComposerPage {

	protected int64 char_limit { get; set; default = 500; }
	protected int64 remaining_chars { get; set; default = 0; }
	public signal void ctrl_return_pressed ();

	construct {
		//  translators: "Text" as in text-based input
		title = _("Text");
		icon_name = "document-edit-symbolic";

		var char_limit_api = accounts.active.instance_info.compat_status_max_characters;
		if (char_limit_api > 0)
			char_limit = char_limit_api;
		remaining_chars = char_limit;
	}

	public override void on_build () {
		base.on_build ();

		install_editor ();
		install_overlay (status.status);
		install_visibility (status.visibility);
		install_languages (status.language);
		add_button (new Gtk.Separator (Orientation.VERTICAL));
		install_cw (status.spoiler_text);
		add_button (new Gtk.Separator (Orientation.VERTICAL));
		install_emoji_picker ();

		validate ();
	}

	protected virtual signal void recount_chars () {}

	protected void validate () {
		recount_chars ();
	}

	public override void on_push () {
		status.status = editor.buffer.text;
		status.sensitive = cw_button.active;
		if (status.sensitive) {
			status.spoiler_text = cw_entry.text;
		}

		var instance_visibility = (visibility_button.selected_item as InstanceAccount.Visibility);
		if (visibility_button != null && visibility_button.selected_item != null && instance_visibility != null)
			status.visibility = instance_visibility.id;

		if (language_button != null && language_button.selected_item != null) {
			status.language = ((Tuba.Locale) language_button.selected_item).locale;
		}
	}

	public override void on_modify_body (Json.Builder builder) {
		builder.set_member_name ("status");
		builder.add_string_value (status.status);

		builder.set_member_name ("visibility");
		builder.add_string_value (status.visibility);

		builder.set_member_name ("language");
		builder.add_string_value (status.language);

		if (status.in_reply_to_id != null && !edit_mode) {
			builder.set_member_name ("in_reply_to_id");
			builder.add_string_value (status.in_reply_to_id);
		}

		builder.set_member_name ("sensitive");
		builder.add_boolean_value (status.sensitive);
		builder.set_member_name ("spoiler_text");
		builder.add_string_value (status.sensitive ? status.spoiler_text : "");
	}

	#if MISSING_GTKSOURCEVIEW
		protected TextView editor;
	#else
		protected GtkSource.View editor;
	#endif
	protected Label char_counter;

	public void editor_grab_focus () {
		editor.grab_focus ();
	}

	protected void install_editor () {
		recount_chars.connect (() => {
			remaining_chars = char_limit;
			#if !MISSING_GTKSOURCEVIEW
				editor.show_completion ();
			#endif
		});
		recount_chars.connect_after (() => {
			placeholder.visible = remaining_chars == char_limit;
			char_counter.label = remaining_chars.to_string ();
			if (remaining_chars < 0) {
				char_counter.add_css_class ("error");
				can_publish = false;
			} else {
				char_counter.remove_css_class ("error");
				can_publish = remaining_chars != char_limit;
			}
		});

		#if MISSING_GTKSOURCEVIEW
			editor = new TextView () {
		#else
			editor = new GtkSource.View () {
		#endif
			vexpand = true,
			hexpand = true,
			top_margin = 6,
			right_margin = 6,
			bottom_margin = 6,
			left_margin = 6,
			pixels_below_lines = 6,
			accepts_tab = false,
			wrap_mode = WrapMode.WORD_CHAR
		};

		#if LIBSPELLING && !MISSING_GTKSOURCEVIEW
			var adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) editor.buffer, Spelling.Checker.get_default ());

			editor.extra_menu = adapter.get_menu_model ();
			editor.insert_action_group ("spelling", adapter);
			adapter.enabled = true;
		#endif

		#if GSPELL && (MISSING_GTKSOURCEVIEW || !LIBSPELLING)
			var gspell_view = Gspell.TextView.get_from_gtk_text_view (editor);
			gspell_view.basic_setup ();
		#endif

		var keypress_controller = new Gtk.EventControllerKey ();
        keypress_controller.key_pressed.connect ((keyval, _, modifier) => {
            if (keyval == Gdk.Key.Return && modifier == Gdk.ModifierType.CONTROL_MASK) {
				ctrl_return_pressed ();
				return true;
			}
            return false;
        });
        editor.add_controller (keypress_controller);

		#if !MISSING_GTKSOURCEVIEW
			editor.completion.add_provider (new Tuba.HandleProvider ());
			editor.completion.add_provider (new Tuba.HashtagProvider ());
			editor.completion.add_provider (new Tuba.EmojiProvider ());
			editor.completion.select_on_show = true;
			editor.completion.show_icons = true;
			editor.completion.page_size = 3;
			update_style_scheme ();
		#endif

		recount_chars.connect (() => {
			remaining_chars -= editor.buffer.get_char_count ();
		});

		char_counter = new Label (char_limit.to_string ()) {
			margin_end = 6,
			tooltip_text = _("Characters Left"),
			css_classes = { "heading" }
		};
		bottom_bar.pack_end (char_counter);
		editor.buffer.changed.connect (validate);
	}

	#if !MISSING_GTKSOURCEVIEW
		protected void update_style_scheme () {
			var manager = GtkSource.StyleSchemeManager.get_default ();
			var scheme = manager.get_scheme ("adwaita");
			var buffer = editor.buffer as GtkSource.Buffer;
			buffer.style_scheme = scheme;
		}
	#endif

	protected Overlay overlay;
	protected Label placeholder;

	protected void install_overlay (string t_content) {
		overlay = new Overlay ();
		placeholder = new Label (_("What's on your mind?")) {
			valign = Align.START,
			halign = Align.START,
			justify = Justification.FILL,
			margin_top = 6,
			margin_start = 6,
			wrap = true,
			sensitive = false
		};

		overlay.add_overlay (placeholder);
		overlay.child = new ScrolledWindow () {
			hexpand = true,
			vexpand = true,
			child = editor
		};

		content.prepend (overlay);
		editor.buffer.text = t_content;
	}

	protected EmojiChooser emoji_picker;
	protected void install_emoji_picker () {
		emoji_picker = new EmojiChooser ();
		var emoji_button = new MenuButton () {
			icon_name = "tuba-smile-symbolic",
			popover = emoji_picker,
			tooltip_text = _("Emoji Picker")
		};

		var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
		var custom_emoji_button = new MenuButton () {
			icon_name = "tuba-cat-symbolic",
			popover = custom_emoji_picker,
			tooltip_text = _("Custom Emoji Picker")
		};

		add_button (emoji_button);
		add_button (custom_emoji_button);

		emoji_picker.emoji_picked.connect (on_emoji_picked);
		custom_emoji_picker.emoji_picked.connect (on_emoji_picked);
	}

	protected void on_emoji_picked (string emoji_unicode) {
		editor.buffer.insert_at_cursor (emoji_unicode, emoji_unicode.data.length);
	}

	protected ToggleButton cw_button;
	protected Entry cw_entry;

	protected void install_cw (string? cw_text) {
		cw_entry = new Gtk.Entry () {
			placeholder_text = _("Write your warning here"),
			margin_top = 6,
			margin_end = 6,
			margin_start = 6
		};
		cw_entry.buffer.inserted_text.connect (validate);
		cw_entry.buffer.deleted_text.connect (validate);
		var revealer = new Gtk.Revealer () {
			child = cw_entry
		};
		revealer.add_css_class ("view");
		content.prepend (revealer);

		cw_button = new ToggleButton () {
			icon_name = "tuba-warning-symbolic",
			tooltip_text = _("Content Warning")
		};
		cw_button.toggled.connect (validate);
		cw_button.bind_property ("active", revealer, "reveal_child", GLib.BindingFlags.SYNC_CREATE);
		add_button (cw_button);

		if (cw_text != null && cw_text != "") {
			cw_entry.buffer.set_text ((uint8[]) cw_text);
			cw_button.active = true;
		}

		recount_chars.connect (() => {
			if (cw_button.active)
				remaining_chars -= (int) cw_entry.buffer.length;
		});
	}



	protected DropDown visibility_button;
	protected DropDown language_button;

	private bool _edit_mode = false;
	public override bool edit_mode {
		get {
			return _edit_mode;
		}
		set {
			_edit_mode = value;
			if (visibility_button != null)
				visibility_button.sensitive = !value;
		}
	}

	protected void install_visibility (string default_visibility = settings.default_post_visibility) {
		visibility_button = new DropDown (accounts.active.visibility_list, null) {
			expression = new PropertyExpression (typeof (InstanceAccount.Visibility), null, "name"),
			factory = new BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/icon.ui"),
			list_factory = new BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/full.ui"),
			tooltip_text = _("Post Privacy"),
			sensitive = !edit_mode
		};

		var safe_visibility = accounts.active.visibility.has_key (default_visibility) ? default_visibility : "public";
		uint default_visibility_index;
		if (
			accounts.active.visibility_list.find (
				accounts.active.visibility[safe_visibility],
				out default_visibility_index
			)
		) {
			visibility_button.selected = default_visibility_index;
		}

		add_button (visibility_button);
	}

	protected void install_languages (string? locale_iso) {
		var store = new GLib.ListStore (typeof (Locale));

		foreach (var locale in app.locales) {
			store.append (locale);
		}

		language_button = new DropDown (store, null) {
			expression = new PropertyExpression (typeof (Tuba.Locale), null, "name"),
			factory = new BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language_title.ui"),
			list_factory = new BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language.ui"),
			tooltip_text = _("Post Language"),
			enable_search = true
		};

		if (locale_iso != null) {
			uint default_lang_index;
			if (
				store.find_with_equal_func (
					new Tuba.Locale (locale_iso, null, null),
					Tuba.Locale.compare,
					out default_lang_index
				)
			) {
				language_button.selected = default_lang_index;
			}
		}

		add_button (language_button);
	}
}
