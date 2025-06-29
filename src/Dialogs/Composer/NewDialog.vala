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
	[GtkChild] private unowned Adw.NavigationPage nav_page;

	[GtkChild] private unowned Gtk.ScrolledWindow scroller;
	[GtkChild] private unowned Adw.HeaderBar headerbar;

	[GtkChild] private unowned Gtk.MenuButton native_emojis_button;
	[GtkChild] private unowned Gtk.MenuButton custom_emojis_button;
	[GtkChild] private unowned Gtk.ToggleButton cw_button;
	[GtkChild] private unowned Gtk.Entry cw_entry;
	[GtkChild] private unowned Gtk.ToggleButton poll_button;
	[GtkChild] private unowned Gtk.ToggleButton sensitive_media_button;
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
			validate_post_button ();

			if (value < 0) {
				counter_label.add_css_class ("error");
				counter_label.remove_css_class ("accented-color");
			} else {
				counter_label.remove_css_class ("error");
				counter_label.add_css_class ("accented-color");
			}
		}
	}

	private bool edit_mode { get; set; default = false; }
	private string? schedule_iso8601 { get; set; default=null; }

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

		editor.edit_mode = this.edit_mode;
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
	protected Gtk.DropDown? content_type_button = null;

	private void append_dropdown (Gtk.DropDown dropdown) {
		var togglebtn = dropdown.get_first_child ();
		if (togglebtn != null) {
			togglebtn.add_css_class ("flat");
		}

		dropdowns_box.append (dropdown);
	}

	protected void install_visibility (string default_visibility) {
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

	private void install_languages (string? locale_iso) {
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

	public delegate void SuccessCallback (API.Status cb_status);
	protected SuccessCallback? cb;

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

	private void on_vadjustment_value_changed () {
		headerbar.show_title = scroller.vadjustment.value > 0;
	}

	public NewCompose (
		string post_button_label = _("Post"),
		string default_visibility = settings.default_post_visibility,
		string default_language = settings.default_language,
		bool edit_mode = false
	) {
		Object ();

		this.edit_mode = edit_mode;
		install_editor ();
		install_emoji_pickers ();
		install_visibility (default_visibility);
		install_languages (default_language);
		install_post_button (post_button_label, !this.edit_mode);
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
		this.set_title (_("New Post"), null);
	}

	public NewCompose.reply (API.Status to, owned SuccessCallback? t_cb = null) {
		string final_visibility = to.visibility;
		var default_visibility = API.Status.Visibility.from_string (settings.default_post_visibility);
		var to_visibility = API.Status.Visibility.from_string (to.visibility);
		if (default_visibility != null && to_visibility != null && default_visibility.privacy_rate () > to_visibility.privacy_rate ()) {
			final_visibility = settings.default_post_visibility;
		}

		this (_("Reply"), final_visibility, to.language);
		Widgets.Status? widget_status = null;
		try {
			var sample = new API.Status.empty () {
				poll = to.poll,
				sensitive = to.sensitive,
				media_attachments = to.media_attachments,
				visibility = to.visibility,
				tuba_spoiler_revealed = true,
				content = to.content,
				spoiler_text = to.spoiler_text,
				account = to.account,
				created_at = to.created_at
			};

			if (sample.formal.has_media) {
				sample.formal.media_attachments.foreach (e => {
					e.tuba_is_report = true;

					return true;
				});
			}

			widget_status = (Widgets.Status?) sample.to_widget ();
			widget_status.add_css_class ("card");
			widget_status.add_css_class ("initial-font-size");
			widget_status.to_display_only ();
		} catch (Error e) {
			warning (@"Couldn't create status widget: $(e.message)");
		}

		this.set_title (_("Reply to @%s").printf (to.account.username), widget_status);
		this.scroller.vadjustment.value = editor.top_margin;
		this.cb = (owned) t_cb;

		// TODO: ellipsize long button labels
	}

	public NewCompose.edit (API.Status t_status, API.StatusSource? source = null, owned SuccessCallback? t_cb = null) {
		this (_("Edit"), t_status.visibility, t_status.language, true);

		//  var template = new API.Status.empty () {
		//  	id = t_status.id,
		//  	poll = t_status.poll,
		//  	sensitive = t_status.sensitive,
		//  	media_attachments = t_status.media_attachments,
		//  	visibility = t_status.visibility,
		//  	language = t_status.language
		//  };

		//  if (source == null) {
		//  	template.content = Utils.Htmlx.remove_tags (t_status.content);
		//  } else {
		//  	template.content = source.text;
		//  	template.spoiler_text = source.spoiler_text;
		//  }

		cw_button.active = t_status.sensitive;
		if (source == null) {
			editor.buffer.text = Utils.Htmlx.remove_tags (t_status.content);
			cw_entry.text = t_status.spoiler_text;
		} else {
			editor.buffer.text = source.text;
			cw_entry.text = source.spoiler_text;
		}

		if (t_status.poll != null) {
			init_polls_component (t_status.poll);
			poll_button.active = true;
		} else if (t_status.media_attachments != null && t_status.media_attachments.size > 0) {
			create_attachmentsbin (t_status.media_attachments);
			editor.add_bottom_child (attachmentsbin_component);
			//  poll_button.sensitive = false; // TODO?
		}

		this.set_title (_("Edit Post"), null);

		this.cb = (owned) t_cb;
	}

	private inline void set_title (string new_title, Gtk.Widget? widget_status) {
		this.title = new_title;
		nav_page.title = new_title;
		editor.set_title (new_title, widget_status);
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
			init_polls_component ();
		} else if (polls_animation.state == PLAYING) polls_animation.skip ();

		editor.add_bottom_child (polls_component);
		polls_animation.reverse = false;
		polls_animation.play ();
	}

	private void init_polls_component (API.Poll? poll_obj = null) {
		if (polls_component != null) return;

		polls_component = new Components.Polls (poll_obj) {
			opacity = 0
		};
		polls_animation = new Adw.TimedAnimation (polls_component, 0, 1, 250, new Adw.PropertyAnimationTarget (polls_component, "opacity"));
		polls_animation.done.connect (on_component_animation_end);
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
		sensitive_media_button.visible = !attachmentsbin_component.is_empty;
		poll_button.sensitive = !is_used;
		if (!is_used) editor.add_bottom_child (null);
		validate_post_button ();
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

	private void create_attachmentsbin (Gee.ArrayList<API.Attachment>? attachments_obj = null) {
		if (attachmentsbin_component != null) return;
		attachmentsbin_component = new Components.AttachmentsBin ();
		attachmentsbin_component.notify["uploading"].connect (update_attachmentsbin_meta);
		attachmentsbin_component.notify["is-empty"].connect (update_attachmentsbin_meta);

		if (attachments_obj != null && attachments_obj.size > 0) {
			foreach (var attachment_obj in attachments_obj) {
				attachmentsbin_component.preload_attachment (attachment_obj);
			}
		}
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

		var schedule_dlg = new Dialogs.Schedule ();
		schedule_dlg.schedule_picked.connect (on_schedule_picked);
		on_push_subpage (schedule_dlg);
	}

	private void on_draft_action_activated () {
		if (!post_btn.sensitive) return;

		this.schedule_iso8601 = (new GLib.DateTime.now ()).add_years (3000).format_iso8601 ();
		//  on_commit ();
	}

	private void on_schedule_picked (string iso8601) {
		this.schedule_iso8601 = iso8601;
		//  on_commit ();
	}

	private void on_component_animation_end (Adw.Animation animation) {
		if (animation.value == 0) editor.add_bottom_child (null);
		validate_post_button (); // ?
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

	private void validate_post_button () {
		bool sensitive = remaining_chars >= 0;
		if (sensitive) {
			if (attachmentsbin_component != null && editor.is_bottom_child (attachmentsbin_component)) {
				sensitive = !attachmentsbin_component.is_empty && !attachmentsbin_component.uploading; // TODO attachable.working
			} else if (polls_component != null && editor.is_bottom_child (polls_component)) {
				sensitive = polls_component.is_valid && remaining_chars < char_limit; // TODO: check if is_valid ignores empties
			} else {
				sensitive = remaining_chars < char_limit;
			}
		}

		post_btn.sensitive = sensitive;
	}

	private Json.Builder populate_json_body () {
		var builder = new Json.Builder ();
		builder.begin_object ();

		//  builder.set_member_name ("status");
		//  builder.add_string_value (status.status);

		if (visibility_button.selected != Gtk.INVALID_LIST_POSITION) {
			builder.set_member_name ("visibility");
			builder.add_string_value (((InstanceAccount.Visibility) visibility_button.selected_item).id);
		}

		// Move to editor?
		builder.set_member_name ("language");
		builder.add_string_value (editor.locale);

		if (content_type_button != null && content_type_button.selected != Gtk.INVALID_LIST_POSITION) {
			builder.set_member_name ("content_type");
			builder.add_string_value (((InstanceAccount.StatusContentType) content_type_button.selected_item).mime);
		}

		//  if (status.in_reply_to_id != null && !edit_mode) {
		//  	builder.set_member_name ("in_reply_to_id");
		//  	builder.add_string_value (status.in_reply_to_id);
		//  }

		builder.set_member_name ("sensitive");
		builder.add_boolean_value (cw_button.active);
		builder.set_member_name ("spoiler_text");
		builder.add_string_value (cw_button.active ? cw_entry.text : "");

		//  if (this.edit_mode) update_metadata (builder);
		//  if (quote_id != null) {
		//  	builder.set_member_name ("quote_id");
		//  	builder.add_string_value (quote_id);
		//  }

		if (this.schedule_iso8601 != null) {
			builder.set_member_name ("scheduled_at");
			builder.add_string_value (schedule_iso8601);
		}

		builder.end_object ();
		return builder;
	}
}
