[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/new_composer.ui")]
public class Tuba.Dialogs.NewCompose : Adw.Dialog {
	[GtkChild] private unowned Gtk.Label counter_label;
	[GtkChild] private unowned Adw.Bin post_btn;
	[GtkChild] private unowned Gtk.Box btns_box;
	[GtkChild] private unowned Gtk.Box dropdowns_box;
	[GtkChild] private unowned Gtk.Grid grid;
	[GtkChild] private unowned Adw.ToastOverlay toast_overlay;
	[GtkChild] private unowned Adw.NavigationView nav_view;
	[GtkChild] private unowned Adw.ToolbarView toolbar_view;
	[GtkChild] private unowned Components.DropOverlay drop_overlay;

	[GtkChild] private unowned Gtk.ScrolledWindow scroller;
	[GtkChild] private unowned Adw.HeaderBar headerbar;
	//  [GtkChild] private unowned Gtk.Box status_box;
	//  [GtkChild] private unowned Gtk.Box main_box;
	//  [GtkChild] private unowned Gtk.Label status_title;

	[GtkChild] private unowned Gtk.MenuButton native_emojis_button;
	[GtkChild] private unowned Gtk.MenuButton custom_emojis_button;
	[GtkChild] private unowned Gtk.ToggleButton cw_button;
	[GtkChild] private unowned Gtk.Entry cw_entry;
	[GtkChild] private unowned Gtk.ToggleButton poll_button;
	[GtkChild] private unowned Gtk.Button add_media_button;

	private bool _is_narrow = false;
	public bool is_narrow {
		get {
			return _is_narrow;
		}
		set {
			Gtk.GridLayout layout_manager = (Gtk.GridLayout) grid.get_layout_manager ();
			Gtk.GridLayoutChild counter_layout_child = (Gtk.GridLayoutChild) layout_manager.get_layout_child (counter_label);
			Gtk.GridLayoutChild post_layout_child = (Gtk.GridLayoutChild) layout_manager.get_layout_child (post_btn);
			Gtk.GridLayoutChild btns_layout_child = (Gtk.GridLayoutChild) layout_manager.get_layout_child (btns_box);

			if (value) {
				post_layout_child.column = 1;
				post_layout_child.row = 1;
				post_layout_child.row_span = 1;

				counter_layout_child.row = 0;
				counter_layout_child.column = 1;

				btns_layout_child.column_span = 1;

				counter_label.margin_end = 10;
				counter_label.margin_start = 0;
				grid.row_spacing = 12;
				editor.margin_start = cw_entry.margin_start = grid.margin_start = 16;
				editor.margin_end = cw_entry.margin_end = grid.margin_end = 16;
			} else {
				post_layout_child.column = 2;
				post_layout_child.row = 0;
				post_layout_child.row_span = 2;

				counter_layout_child.row = 1;
				counter_layout_child.column = 1;

				btns_layout_child.column_span = 2;

				counter_label.margin_end = 0;
				counter_label.margin_start = 12;
				grid.row_spacing = 16;
				editor.margin_start = cw_entry.margin_start = grid.margin_start = 32;
				editor.margin_end = cw_entry.margin_end = grid.margin_end = 32;
			}

			_is_narrow = value;
		}
	}
	protected int64 char_limit { get; set; default = 500; }
	protected int64 cw_count { get; set; default = 0; }

	private int64 _remaining_chars = 500;
	protected int64 remaining_chars {
		get {
			return _remaining_chars;
		}
		set {
			_remaining_chars = value;
			counter_label.label = counter_label.tooltip_text = char_limit >= 1000 ? value.to_string () : @"$value / $char_limit";

			if (value < 0) {
				counter_label.add_css_class ("error");
				counter_label.remove_css_class ("accented-color");
			} else {
				counter_label.remove_css_class ("error");
				counter_label.add_css_class ("accented-color");
			}
		}
	}

	private void install_emoji_pickers () {
		var emoji_picker = new Gtk.EmojiChooser ();
		native_emojis_button.popover = emoji_picker;
		emoji_picker.emoji_picked.connect (editor.insert_string_at_cursor);

		if (accounts.active.instance_emojis != null && accounts.active.instance_emojis.size > 0) {
			var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
			custom_emojis_button.popover = custom_emoji_picker;
			custom_emoji_picker.emoji_picked.connect (editor.insert_string_at_cursor);
		}
	}

	private Components.Editor editor;
	private void install_editor () {
		editor = new Dialogs.Components.Editor () {
			margin_end = 32,
			margin_start = 32
		};

		scroller.overflow = HIDDEN;
		scroller.child = editor;

		editor.toast.connect (on_toast);
		editor.push_subpage.connect (on_push_subpage);
		editor.pop_subpage.connect (on_pop_subpage);
		editor.paste_clipboard.connect (on_paste);
		editor.notify["char-count"].connect (update_remaining_chars);
		this.focus_widget = editor;
	}

	private void update_remaining_chars () {
		remaining_chars = this.char_limit - editor.char_count - this.cw_count;
	}

	protected Gtk.DropDown visibility_button;
	protected Gtk.DropDown language_button;
	protected Gtk.DropDown content_type_button;

	private void append_dropdown (Gtk.DropDown dropdown) {
		var togglebtn = dropdown.get_first_child ();
		if (togglebtn != null) {
			togglebtn.add_css_class ("flat");
		}

		dropdowns_box.append (dropdown);
	}

	protected void install_visibility (string default_visibility = settings.default_post_visibility) {
		visibility_button = new Gtk.DropDown (accounts.active.visibility_list, null) {
			expression = new Gtk.PropertyExpression (typeof (InstanceAccount.Visibility), null, "name"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/icon.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/full.ui"),
			tooltip_text = _("Post Privacy"),
			valign = Gtk.Align.CENTER
		};
		visibility_button.add_css_class ("dropdown-border-radius");

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

		append_dropdown (visibility_button);
	}

	private void install_languages (string? locale_iso = null) {
		language_button = new Gtk.DropDown (app.app_locales.list_store, null) {
			expression = new Gtk.PropertyExpression (typeof (Utils.Locales.Locale), null, "name"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language_title.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language.ui"),
			tooltip_text = _("Post Language"),
			enable_search = true,
			valign = Gtk.Align.CENTER
		};
		language_button.add_css_class ("dropdown-border-radius");

		if (locale_iso != null) {
			uint default_lang_index;
			if (
				app.app_locales.list_store.find_with_equal_func (
					new Utils.Locales.Locale (locale_iso, null, null),
					Utils.Locales.Locale.compare,
					out default_lang_index
				)
			) {
				language_button.selected = default_lang_index;
			}
		}

		language_button.notify["selected"].connect (on_language_changed);
		append_dropdown (language_button);
	}

	private void on_language_changed () {
		if (language_button.selected == Gtk.INVALID_LIST_POSITION) return;

		var locale_obj = language_button.selected_item as Utils.Locales.Locale;
		if (locale_obj == null || locale_obj.locale == null) return;

		editor.locale = locale_obj.locale;
		cw_changed_with_locale (locale_obj.locale);
	}

	private void cw_changed () {
		string locale_icu = "en";
		if (
			language_button != null
			&& ((Utils.Locales.Locale) language_button.selected_item) != null
			&& ((Utils.Locales.Locale) language_button.selected_item).locale != null
		) {
			locale_icu = ((Utils.Locales.Locale) language_button.selected_item).locale;
		}

		cw_changed_with_locale (locale_icu);
	}

	private void cw_changed_with_locale (string locale) {
		int cw_count = 0;
		if (cw_button.active) cw_count = Utils.Counting.chars (cw_entry.text, locale);
		if (cw_count != this.cw_count) {
			this.cw_count = cw_count;
			update_remaining_chars ();
		}
	}

	static construct {
		typeof (Components.DropOverlay).ensure ();
	}

	construct {
		var condition = new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			400, Adw.LengthUnit.SP
		);
		var breakpoint = new Adw.Breakpoint (condition);
		breakpoint.add_setter (this, "is-narrow", true);
		add_breakpoint (breakpoint);

		var schedule_action = new SimpleAction ("schedule", null);
		schedule_action.activate.connect (on_schedule_action_activated);

		var draft_action = new SimpleAction ("draft", null);
		draft_action.activate.connect (on_draft_action_activated);

		var action_group = new GLib.SimpleActionGroup ();
		action_group.add_action (schedule_action);
		action_group.add_action (draft_action);

		this.insert_action_group ("composer", action_group);

		var char_limit_api = accounts.active.instance_info.compat_status_max_characters;
		if (char_limit_api > 0)
			char_limit = char_limit_api;

		var dnd_controller = new Gtk.DropTarget (typeof (Gdk.FileList), Gdk.DragAction.COPY) {
			propagation_phase = CAPTURE
		};
		dnd_controller.enter.connect (on_drag_enter);
		dnd_controller.leave.connect (on_drag_leave);
		dnd_controller.drop.connect (on_drag_drop);
		toolbar_view.add_controller (dnd_controller);

		install_editor ();
		install_emoji_pickers ();
		install_visibility ();
		install_languages ();
		install_post_button (_("Post"), true);
		if (accounts.active.supported_mime_types.n_items > 1)
			install_content_types (settings.default_content_type);

		cw_entry.changed.connect (cw_changed);
		cw_button.toggled.connect (cw_changed);
		on_language_changed ();

		update_remaining_chars ();
		present (app.main_window);

		scroller.vadjustment.value_changed.connect (on_vadjustment_value_changed);
		poll_button.toggled.connect (toggle_poll_component);
		toggle_poll_component ();

		add_media_button.clicked.connect (on_add_media_clicked);
	}

	private void install_post_button (string label, bool with_menu) {
		if (with_menu) {
			var menu_model = new GLib.Menu ();
			// translators: 'Draft' is a verb
			menu_model.append (_("Draft Post"), "composer.draft");

			// translators: 'Schedule' is a verb
			menu_model.append (_("Schedule Post…"), "composer.schedule");

			var btn = new Adw.SplitButton () {
				label = label,
				menu_model = menu_model,
				css_classes = { "pill", "suggested-action" }
			};
			post_btn.child = btn;
		} else {
			var btn = new Gtk.Button.with_label (label) {
				css_classes = { "pill", "suggested-action" }
			};
			post_btn.child = btn;
		}
	}

	private void install_content_types (string? content_type) {
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

		unowned Gtk.Widget? actual_button = content_type_button.get_first_child () as Gtk.ToggleButton;
		if (actual_button != null) actual_button.add_css_class ("flat");

		headerbar.pack_start (content_type_button);
		content_type_button.notify["selected-item"].connect (on_content_type_changed);
		on_content_type_changed ();
	}

	private void on_content_type_changed () {
		if (content_type_button.selected == Gtk.INVALID_LIST_POSITION) return;

		var ct_obj = content_type_button.selected_item as InstanceAccount.StatusContentType;
		if (ct_obj == null || ct_obj.syntax == null) return;

		editor.content_type = ct_obj.syntax;
	}

	bool _a = false;
	public bool a {
		get { return _a; }
		set {
			_a = value;
			editor.queue_resize ();
		}
	}

	private void on_vadjustment_value_changed () {
		headerbar.show_title = scroller.vadjustment.value > 0;
	}

	public NewCompose (API.Status template = new API.Status.empty ()) {
		Object ();

		this.title = _("New Post");
	}

	public NewCompose.reply (API.Status to) {
		Object ();

		try {
			Widgets.Status widget_status = (Widgets.Status?) to.to_widget ();
			widget_status.add_css_class ("card");
			widget_status.actions.visible = false;
			widget_status.menu_button.visible = false;
			widget_status.activatable = false;
			widget_status.can_target = false;
			widget_status.can_focus = false;

			//  status_box.insert_child_after (widget_status, status_title);
		} catch (Error e) {
			warning (@"Couldn't create status widget: $(e.message)");
		}

		//  status_title.label = _("Reply to %s").printf (to.account.handle);
	}


	Components.Polls? polls_component = null;
	Adw.TimedAnimation? polls_animation = null;
	private void toggle_poll_component () {
		if (!poll_button.active) {
			if (polls_animation != null) {
				polls_animation.reverse = true;
				polls_animation.play ();
			} else {
				editor.add_bottom_child (null);
			}
			return;
		}

		if (polls_component == null) {
			polls_component = new Components.Polls () {
				opacity = 0
			};
			polls_animation = new Adw.TimedAnimation (polls_component, 0, 1, 250, new Adw.PropertyAnimationTarget (polls_component, "opacity"));
			polls_animation.done.connect (on_component_animation_end);
		} else if (polls_animation.state == PLAYING) polls_animation.skip ();

		editor.add_bottom_child (polls_component);
		polls_animation.reverse = false;
		polls_animation.play ();
	}

	Components.AttachmentsBin? attachmentsbin_component = null;
	private void on_add_media_clicked () {
		create_attachmentsbin ();
		attachmentsbin_component.show_file_selector ();
		editor.add_bottom_child (attachmentsbin_component);
	}

	private void update_attachmentsbin_meta () {
		if (attachmentsbin_component == null) return;

		bool is_used = attachmentsbin_component.uploading || !attachmentsbin_component.is_empty;
		poll_button.sensitive = !is_used;
		if (!is_used) editor.add_bottom_child (null);
	}

	private bool on_drag_drop (Value val, double x, double y) {
		drop_overlay.dropping = false;
		if (!add_media_button.sensitive) return false;

		var file_list = val as Gdk.FileList;
		if (file_list == null) return false;

		var files = file_list.get_files ();
		if (files.length () == 0) return false;

		File[] files_to_upload = {};
		foreach (var file in files) {
			files_to_upload += file;
		}
		if (files_to_upload.length == 0) return false;

		create_attachmentsbin ();
		attachmentsbin_component.upload_files.begin (files_to_upload);
		editor.add_bottom_child (attachmentsbin_component);

		return true;
	}

	private Gdk.DragAction on_drag_enter (double x, double y) {
		drop_overlay.dropping = true;
		return Gdk.DragAction.COPY;
	}

	private void on_drag_leave () {
		drop_overlay.dropping = false;
	}

	private async void on_clipboard_paste_async (Gdk.Clipboard clipboard) {
		File[] files = {};

		try {
			var copied_value = yield clipboard.read_value_async (typeof (File), 0, null);

			if (copied_value != null) {
				var copied_file = copied_value as File;
				if (copied_file != null) {
					files += copied_file;
				}
			}
		} catch (Error e) {}

		if (files.length == 0) {
			try {
				var copied_texture = yield clipboard.read_texture_async (null);
				if (copied_texture == null) return;

				FileIOStream stream;
				files += yield File.new_tmp_async ("tuba-XXXXXX.png", GLib.Priority.DEFAULT, null, out stream);

				OutputStream ostream = stream.output_stream;
				yield ostream.write_bytes_async (copied_texture.save_to_png_bytes ());
			} catch (Error e) {
				warning (@"Couldn't get texture from clipboard: $(e.message)");
			}
		}

		yield attachmentsbin_component.upload_files (files);
	}

	private void create_attachmentsbin () {
		if (attachmentsbin_component != null) return;
		attachmentsbin_component = new Components.AttachmentsBin ();
		attachmentsbin_component.notify["uploading"].connect (update_attachmentsbin_meta);
		attachmentsbin_component.notify["is-empty"].connect (update_attachmentsbin_meta);
	}

	private void on_paste () {
		Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
		var formats = clipboard.get_formats ();
		bool has_files = formats.contain_mime_type ("text/uri-list");
		if (!has_files) {
			var mime_types = formats.get_mime_types ();
			if (mime_types == null) return;

			foreach (string mime_type in mime_types) {
				if (mime_type.has_prefix ("image/")) {
					has_files = true;
					break;
				}
			}
		}
		if (!has_files) return;

		Signal.stop_emission_by_name (editor, "paste-clipboard");
		app.question.begin (
			{_("Paste Media from Clipboard?"), false},
			// translators: they = media / files from clipboard, instance = server
			{_("They will be uploaded to your instance"), false},
			this,
			{ { _("Paste"), Adw.ResponseAppearance.SUGGESTED }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			null,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) {
					create_attachmentsbin ();
					on_clipboard_paste_async.begin (clipboard);
					editor.add_bottom_child (attachmentsbin_component);
				}
			}
		);
    }

	private void on_schedule_action_activated () {
		if (!post_btn.sensitive) return;

		on_push_subpage (new Dialogs.Schedule ());
		//  schedule_dlg.schedule_picked.connect (on_schedule_picked);
	}

	private void on_draft_action_activated () {
		if (!post_btn.sensitive) return;

		//  schedule_iso8601 = (new GLib.DateTime.now ()).add_years (3000).format_iso8601 ();
		//  on_commit ();
	}

	private void on_component_animation_end (Adw.Animation animation) {
		if (animation.value == 0) editor.add_bottom_child (null);
	}

	private void on_toast (Adw.Toast toast) {
		toast_overlay.add_toast (toast);
	}

	private void on_push_subpage (Adw.NavigationPage page) {
		nav_view.push (page);
	}

	private void on_pop_subpage () {
		nav_view.pop ();
	}
}
