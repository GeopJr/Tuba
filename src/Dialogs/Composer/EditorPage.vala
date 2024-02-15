public class Tuba.EditorPage : ComposerPage {
	public bool force_cursor_at_start { get; construct set; default=false; }
	protected int64 char_limit { get; set; default = 500; }
	protected int64 remaining_chars { get; set; default = 0; }
	public signal void ctrl_return_pressed ();

	private bool hide_dropdown_arrows {
		set {
			Gtk.DropDown?[] dropdown_widgets = {visibility_button, language_button, content_type_button};
			foreach (Gtk.DropDown? dropdown in dropdown_widgets) {
				if (dropdown != null) dropdown.show_arrow = !value;
			}
		}
	}

	public Adw.ToastOverlay toast_overlay;
	construct {
		//  translators: "Text" as in text-based input
		title = _("Text");
		icon_name = "document-edit-symbolic";

		var char_limit_api = accounts.active.instance_info.compat_status_max_characters;
		if (char_limit_api > 0)
			char_limit = char_limit_api;
		remaining_chars = char_limit;

		toast_overlay = new Adw.ToastOverlay ();
	}

	public void set_cursor_at_start () {
		Gtk.TextIter star_iter;
		editor.buffer.get_start_iter (out star_iter);
		editor.buffer.place_cursor (star_iter);
	}

	public override void on_build () {
		base.on_build ();
		bool supports_mime_types = accounts.active.supported_mime_types.n_items > 1;

		install_editor ();
		install_overlay (status.status);
		install_visibility (status.visibility);
		install_languages (status.language);

		if (supports_mime_types)
			install_content_type_button (settings.default_content_type);
		add_button (new Gtk.Separator (Gtk.Orientation.VERTICAL));
		install_cw (status.spoiler_text);
		add_button (new Gtk.Separator (Gtk.Orientation.VERTICAL));
		install_emoji_picker ();

		validate ();

		if (supports_mime_types) hide_dropdown_arrows = true;
	}

	protected virtual signal void recount_chars () {}

	protected void validate () {
		recount_chars ();
	}

	protected void on_paste (Gdk.Clipboard clp) {
		if (!settings.strip_tracking) return;
		var clean_buffer = Tracking.cleanup_content_with_uris (
			editor.buffer.text,
			Tracking.extract_uris (editor.buffer.text),
			Tracking.CleanupType.STRIP_TRACKING
		);
		if (clean_buffer == editor.buffer.text) return;

		Gtk.TextIter start_iter;
		Gtk.TextIter end_iter;
		editor.buffer.get_bounds (out start_iter, out end_iter);
		editor.buffer.begin_user_action ();
		editor.buffer.delete (ref start_iter, ref end_iter);
		editor.buffer.insert (ref start_iter, clean_buffer, -1);
		editor.buffer.end_user_action ();

		var toast = new Adw.Toast (
			_("Stripped tracking parameters")
		) {
			timeout = 3,
			button_label = _("Undo")
		};
		toast.button_clicked.connect (undo);
		toast_overlay.add_toast (toast);
	}

	private void undo () {
		editor.buffer.undo ();
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
			status.language = ((Tuba.Locales.Locale) language_button.selected_item).locale;
		}

		if (content_type_button != null && content_type_button.selected_item != null) {
			status.content_type = ((Tuba.InstanceAccount.StatusContentType) content_type_button.selected_item).mime;
		}
	}

	public override void on_modify_body (Json.Builder builder) {
		builder.set_member_name ("status");
		builder.add_string_value (status.status);

		builder.set_member_name ("visibility");
		builder.add_string_value (status.visibility);

		builder.set_member_name ("language");
		builder.add_string_value (status.language);

		if (status.content_type != null) {
			builder.set_member_name ("content_type");
			builder.add_string_value (status.content_type);
		}

		if (status.in_reply_to_id != null && !edit_mode) {
			builder.set_member_name ("in_reply_to_id");
			builder.add_string_value (status.in_reply_to_id);
		}

		builder.set_member_name ("sensitive");
		builder.add_boolean_value (status.sensitive);
		builder.set_member_name ("spoiler_text");
		builder.add_string_value (status.sensitive ? status.spoiler_text : "");
	}

	protected GtkSource.View editor;
	protected Gtk.Label char_counter;

	public void editor_grab_focus () {
		editor.grab_focus ();
	}

	#if LIBSPELLING
		protected Spelling.TextBufferAdapter adapter;
		private void update_spelling_settings () {
			settings.spellchecker_enabled = adapter.enabled;
		}
	#endif

	protected void install_editor () {
		recount_chars.connect (() => {
			remaining_chars = char_limit;
			editor.show_completion ();
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


		editor = new GtkSource.View () {
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
		editor.remove_css_class ("view");

		#if LIBSPELLING
			adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) editor.buffer, Spelling.Checker.get_default ());

			editor.extra_menu = adapter.get_menu_model ();
			editor.insert_action_group ("spelling", adapter);

			adapter.enabled = settings.spellchecker_enabled;
			adapter.notify["enabled"].connect (update_spelling_settings);
		#endif

		var keypress_controller = new Gtk.EventControllerKey ();
        keypress_controller.key_pressed.connect ((keyval, _, modifier) => {
            modifier &= Gdk.MODIFIER_MASK;
            if ((keyval == Gdk.Key.Return || keyval == Gdk.Key.KP_Enter) && (modifier == Gdk.ModifierType.CONTROL_MASK || modifier == (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.LOCK_MASK))) {
				ctrl_return_pressed ();
				return true;
			}
            return false;
        });
        editor.add_controller (keypress_controller);

		editor.completion.add_provider (new Tuba.HandleProvider ());
		editor.completion.add_provider (new Tuba.HashtagProvider ());
		editor.completion.add_provider (new Tuba.EmojiProvider ());
		editor.completion.select_on_show = true;
		editor.completion.show_icons = true;
		editor.completion.page_size = 3;
		update_style_scheme ();

		recount_chars.connect (() => {
			remaining_chars -= editor.buffer.get_char_count ();
		});

		char_counter = new Gtk.Label (char_limit.to_string ()) {
			margin_end = 6,
			tooltip_text = _("Characters Left"),
			css_classes = { "heading" }
		};
		bottom_bar.pack_end (char_counter);
		editor.buffer.changed.connect (validate);
		editor.buffer.paste_done.connect (on_paste);
	}

	protected void update_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		var scheme = manager.get_scheme ("adwaita");
		var buffer = editor.buffer as GtkSource.Buffer;
		buffer.style_scheme = scheme;
	}

	protected Gtk.Overlay overlay;
	protected Gtk.Label placeholder;

	protected void install_overlay (string t_content) {
		overlay = new Gtk.Overlay ();
		placeholder = new Gtk.Label (_("What's on your mind?")) {
			valign = Gtk.Align.START,
			halign = Gtk.Align.START,
			justify = Gtk.Justification.FILL,
			margin_top = 6,
			margin_start = 6,
			wrap = true,
			sensitive = false
		};

		overlay.add_overlay (placeholder);
		overlay.child = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true,
			child = editor
		};

		toast_overlay.child = overlay;
		content.prepend (toast_overlay);
		editor.buffer.text = t_content;
		if (force_cursor_at_start) set_cursor_at_start ();
	}

	protected Gtk.EmojiChooser emoji_picker;
	protected void install_emoji_picker () {
		emoji_picker = new Gtk.EmojiChooser ();
		var emoji_button = new Gtk.MenuButton () {
			icon_name = "tuba-smile-symbolic",
			popover = emoji_picker,
			tooltip_text = _("Emoji Picker")
		};
		add_button (emoji_button);
		emoji_picker.emoji_picked.connect (on_emoji_picked);

		if (accounts.active.instance_emojis?.size > 0) {
			var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
			var custom_emoji_button = new Gtk.MenuButton () {
				icon_name = "tuba-cat-symbolic",
				popover = custom_emoji_picker,
				tooltip_text = _("Custom Emoji Picker")
			};

			add_button (custom_emoji_button);
			custom_emoji_picker.emoji_picked.connect (on_emoji_picked);
		}
	}

	protected void on_emoji_picked (string emoji_unicode) {
		editor.buffer.insert_at_cursor (emoji_unicode, emoji_unicode.data.length);
	}

	protected Gtk.ToggleButton cw_button;
	protected Gtk.Entry cw_entry;

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

		cw_button = new Gtk.ToggleButton () {
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



	protected Gtk.DropDown visibility_button;
	protected Gtk.DropDown language_button;
	protected Gtk.DropDown content_type_button;

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
		visibility_button = new Gtk.DropDown (accounts.active.visibility_list, null) {
			expression = new Gtk.PropertyExpression (typeof (InstanceAccount.Visibility), null, "name"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/icon.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/full.ui"),
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
		language_button = new Gtk.DropDown (app.app_locales.list_store, null) {
			expression = new Gtk.PropertyExpression (typeof (Tuba.Locales.Locale), null, "name"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language_title.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language.ui"),
			tooltip_text = _("Post Language"),
			enable_search = true
		};

		if (locale_iso != null) {
			uint default_lang_index;
			if (
				app.app_locales.list_store.find_with_equal_func (
					new Tuba.Locales.Locale (locale_iso, null, null),
					Tuba.Locales.Locale.compare,
					out default_lang_index
				)
			) {
				language_button.selected = default_lang_index;
			}
		}

		add_button (language_button);
	}

	protected void install_content_type_button (string? content_type) {
		content_type_button = new Gtk.DropDown (accounts.active.supported_mime_types, null) {
			expression = new Gtk.PropertyExpression (typeof (Tuba.InstanceAccount.StatusContentType), null, "title"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/content_type_title.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/content_type.ui"),
			tooltip_text = _("Post Content Type"),
			enable_search = false
		};

		if (content_type != null) {
			uint default_content_type_index;
			if (
				accounts.active.supported_mime_types.find_with_equal_func (
					new Tuba.InstanceAccount.StatusContentType (content_type),
					Tuba.InstanceAccount.StatusContentType.compare,
					out default_content_type_index
				)
			) {
				content_type_button.selected = default_content_type_index;
			}
		}

		add_button (content_type_button);
	}
}
