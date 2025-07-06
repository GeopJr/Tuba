[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/new_composer.ui")]
public class Tuba.Dialogs.NewCompose : Adw.Dialog {
	~NewCompose () {
		debug ("Destroying Composer");
	}

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

	public struct Precompose {
		string? content;
		string? spoiler;
		string? quote_id;
		string? scheduled_id;
		string? in_reply_to_id;
		API.Poll? poll;
		Gee.ArrayList<API.Attachment>? media_attachments;
		bool sensitive_media;
		bool force_cursor_at_start;
	}

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
	private string? in_reply_to_id { get; set; default = null; }
	public string? quote_id { get; set; default = null; }
	public string? scheduled_id { get; set; default = null; }
	public string? edit_status_id { get; set; default = null; }

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
		editor.ctrl_return_pressed.connect (on_commit);
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
		sensitive_media_button.toggled.connect (update_attachmentsbin_sensitivity);
		this.close_attempt.connect (on_exit);
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
			btn.clicked.connect (on_commit);
			post_btn.child = btn;
		} else {
			var btn = new Gtk.Button () {
				css_classes = { "pill", "suggested-action" },
				child = new Gtk.Label (label) {
					ellipsize = END
				}
			};
			btn.clicked.connect (on_commit);
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

	uint unique_state = 0;
	public NewCompose (
		Precompose? precompose = null,
		string default_visibility = settings.default_post_visibility,
		string default_language = settings.default_language,
		string post_button_label = _("Post"),
		bool edit_mode = false,
		bool can_schedule = true
	) {
		Object ();

		this.edit_mode = edit_mode;
		install_editor ();
		install_emoji_pickers ();
		install_visibility (default_visibility);
		install_languages (default_language);
		install_post_button (post_button_label, !this.edit_mode && can_schedule);
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
		this.set_editor_title (_("New Post"), null);

		if (precompose != null) {
			if (precompose.content != null) editor.buffer.text = precompose.content;
			if (precompose.spoiler != null) {
				cw_button.active = precompose.spoiler != "";
				cw_entry.text = precompose.spoiler;
			}
			if (precompose.quote_id != null) this.quote_id = precompose.quote_id;
			if (precompose.scheduled_id != null) this.scheduled_id = precompose.scheduled_id;
			if (precompose.in_reply_to_id != null) this.in_reply_to_id = precompose.in_reply_to_id;

			if (precompose.force_cursor_at_start) {
				Gtk.TextIter star_iter;
				editor.buffer.get_start_iter (out star_iter);
				editor.buffer.place_cursor (star_iter);
			}

			if (precompose.poll != null) {
				init_polls_component (precompose.poll);
				poll_button.active = true;
			} else if (precompose.media_attachments != null && precompose.media_attachments.size > 0) {
				create_attachmentsbin (precompose.media_attachments);
				editor.add_bottom_child (attachmentsbin_component);
				sensitive_media_button.active = precompose.sensitive_media;
			}
		}

		unique_state = generate_unique_state ();
	}

	public NewCompose.reply (API.Status to, owned SuccessCallback? t_cb = null) {
		string final_visibility = to.visibility;
		var default_visibility = API.Status.Visibility.from_string (settings.default_post_visibility);
		var to_visibility = API.Status.Visibility.from_string (to.visibility);
		if (default_visibility != null && to_visibility != null && default_visibility.privacy_rate () > to_visibility.privacy_rate ()) {
			final_visibility = settings.default_post_visibility;
		}

		this ({to.formal.get_reply_mentions (), to.spoiler_text, null, null, to.id, null, null, false, false}, final_visibility, to.language, _("Reply"));

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

		Widgets.Status widget_status = (Widgets.Status?) sample.to_widget ();
		widget_status.add_css_class ("card");
		widget_status.add_css_class ("initial-font-size");
		widget_status.to_display_only ();

		this.set_editor_title (_("Reply to @%s").printf (to.account.username), widget_status);
		this.scroller.vadjustment.value = editor.top_margin;
		this.cb = (owned) t_cb;
	}

	public NewCompose.quote (API.Status to, API.Status.Visibility? reblog_visibility = null, bool supports_quotes = false) {
		string final_visibility = to.visibility;
		if (reblog_visibility == null) {
			var default_visibility = API.Status.Visibility.from_string (settings.default_post_visibility);
			var to_visibility = API.Status.Visibility.from_string (to.visibility);
			if (default_visibility != null && to_visibility != null && default_visibility.privacy_rate () > to_visibility.privacy_rate ()) {
				final_visibility = settings.default_post_visibility;
			}
		} else {
			final_visibility = reblog_visibility.to_string ();
		}

		this (
			{
				supports_quotes ? null : @"\n\nRE: $(to.formal.url ?? to.formal.account.url)",
				to.spoiler_text,
				supports_quotes ? to.id : null,
				null,
				null,
				null,
				null,
				false,
				!supports_quotes
			},
			final_visibility,
			to.language,
			_("Quote"),
			false,
			!supports_quotes
		);

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

		Widgets.Status widget_status = (Widgets.Status?) sample.to_widget ();
		widget_status.add_css_class ("card");
		widget_status.add_css_class ("initial-font-size");
		widget_status.to_display_only ();

		this.set_editor_title (_("Quoting @%s").printf (to.account.username), widget_status);
		this.scroller.vadjustment.value = editor.top_margin;
	}

	public NewCompose.edit (API.Status t_status, API.StatusSource? source = null, owned SuccessCallback? t_cb = null) {
		this (
			{
				source == null ? Utils.Htmlx.remove_tags (t_status.content) : source.text,
				source == null ? t_status.spoiler_text : source.spoiler_text,
				null, null, null,
				t_status.poll,
				t_status.media_attachments,
				t_status.sensitive,
				false
			},
			t_status.visibility,
			t_status.language,
			_("Edit"),
			true
		);
		this.edit_status_id = t_status.id;

		this.set_editor_title (_("Edit Post"), null);
		this.cb = (owned) t_cb;
	}

	public NewCompose.from_scheduled (API.ScheduledStatus scheduled_status, bool posting_draft, API.Poll? poll = null, owned SuccessCallback? t_cb = null) {
		this (
			{
				scheduled_status.props.text,
				scheduled_status.props.spoiler_text,
				null,
				posting_draft ? null : scheduled_status.id,
				scheduled_status.props.in_reply_to_id,
				poll,
				scheduled_status.media_attachments,
				scheduled_status.props.sensitive,
				false
			},
			scheduled_status.props.visibility,
			scheduled_status.props.language,
			posting_draft ? _("Post") : _("Edit"),
			false,
			false
		);

		if (!posting_draft) {
			this.set_editor_title (_("Edit Post"), null);
			this.schedule_iso8601 = scheduled_status.scheduled_at;
		}

		this.cb = (owned) t_cb;
	}

	private inline void set_editor_title (string new_title, Gtk.Widget? widget_status) {
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
		polls_component.notify["is-valid"].connect (validate_post_button);
		polls_animation = new Adw.TimedAnimation (polls_component, 0, 1, 250, new Adw.PropertyAnimationTarget (polls_component, "opacity"));
		polls_animation.done.connect (on_component_animation_end);
		this.bind_property ("is-narrow", polls_component, "is-narrow", SYNC_CREATE);
	}

	Components.AttachmentsBin? attachmentsbin_component = null;
	private void on_add_media_clicked () {
		create_attachmentsbin ();
		attachmentsbin_component.show_file_selector ();
		editor.add_bottom_child (attachmentsbin_component);
	}

	private void update_attachmentsbin_meta () {
		if (attachmentsbin_component == null) return;

		bool is_used = attachmentsbin_component.working || !attachmentsbin_component.is_empty;
		sensitive_media_button.visible = !attachmentsbin_component.is_empty;
		poll_button.sensitive = !is_used;
		if (!is_used) editor.add_bottom_child (null);
		validate_post_button ();
		update_attachmentsbin_sensitivity ();
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
		attachmentsbin_component.notify["working"].connect (update_attachmentsbin_meta);
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

		var schedule_dlg = new Dialogs.Schedule (this.schedule_iso8601);
		schedule_dlg.schedule_picked.connect (on_schedule_picked);
		on_push_subpage (schedule_dlg);
	}

	private void on_draft_action_activated () {
		if (!post_btn.sensitive) return;

		this.schedule_iso8601 = (new GLib.DateTime.now ()).add_years (3000).format_iso8601 ();
		on_commit ();
	}

	private void on_schedule_picked (string iso8601) {
		this.schedule_iso8601 = iso8601;
		on_commit ();
	}

	private void on_component_animation_end (Adw.Animation animation) {
		if (animation.value == 0) editor.add_bottom_child (null);
		else if (polls_component != null && editor.is_bottom_child (polls_component)) polls_component.grab_first_row_focus ();
		validate_post_button ();
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
				sensitive = !attachmentsbin_component.is_empty && !attachmentsbin_component.working;
			} else if (polls_component != null && editor.is_bottom_child (polls_component)) {
				sensitive = polls_component.is_valid && remaining_chars < char_limit;
			} else {
				sensitive = remaining_chars < char_limit;
			}
		}

		post_btn.sensitive = sensitive;
	}

	private void update_attachmentsbin_sensitivity () {
		if (attachmentsbin_component == null) return;

		bool has_class = attachmentsbin_component.has_css_class ("spoilered-attachmentsbin");
		if (sensitive_media_button.active && !has_class) {
			attachmentsbin_component.add_css_class ("spoilered-attachmentsbin");
		} else if (!sensitive_media_button.active && has_class) {
			attachmentsbin_component.remove_css_class ("spoilered-attachmentsbin");
		}
	}

	private Json.Builder populate_json_body () {
		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("status");
		builder.add_string_value (editor.buffer.text);

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

		if (in_reply_to_id != null && !edit_mode) {
			builder.set_member_name ("in_reply_to_id");
			builder.add_string_value (this.in_reply_to_id);
		}

		builder.set_member_name ("sensitive");
		builder.add_boolean_value (cw_button.active || (sensitive_media_button.visible && sensitive_media_button.active));
		builder.set_member_name ("spoiler_text");
		builder.add_string_value (cw_button.active ? cw_entry.text : "");

		if (polls_component != null && editor.is_bottom_child (polls_component) && polls_component.is_valid && polls_component.has_rows) {
			builder.set_member_name ("poll");
			builder.begin_object ();
				builder.set_member_name ("multiple");
				builder.add_boolean_value (polls_component.multiple_choice);

				builder.set_member_name ("hide_totals");
				builder.add_boolean_value (polls_component.hide_totals);

				builder.set_member_name ("expires_in");
				builder.add_int_value (polls_component.expires_in);

				builder.set_member_name ("options");
				builder.begin_array ();
					foreach (var option in polls_component.get_all_options ()) {
						builder.add_string_value (option);
					}
				builder.end_array ();
			builder.end_object ();
		} else if (attachmentsbin_component != null && editor.is_bottom_child (attachmentsbin_component) && !attachmentsbin_component.is_empty) {
			builder.set_member_name ("media_ids");
			builder.begin_array ();
				foreach (var m_id in attachmentsbin_component.get_all_media_ids ()) {
					builder.add_string_value (m_id);
				}
			builder.end_array ();

			if (edit_mode) {
				builder.set_member_name ("media_attributes");
				builder.begin_array ();
					foreach (var meta in attachmentsbin_component.get_all_metadata ()) {
						builder.begin_object ();
							builder.set_member_name ("id");
							builder.add_string_value (meta.id);
							builder.set_member_name ("description");
							builder.add_string_value (meta.description);
							builder.set_member_name ("focus");
							builder.add_string_value (meta.focus);
						builder.end_object ();
					}
				builder.end_array ();
			}
		}

		if (this.quote_id != null) {
			builder.set_member_name ("quote_id");
			builder.add_string_value (quote_id);
		}

		if (this.schedule_iso8601 != null) {
			builder.set_member_name ("scheduled_at");
			builder.add_string_value (schedule_iso8601);
		}

		builder.end_object ();
		return builder;
	}

	private void on_commit () {
		if (!this.sensitive) return;
		this.sensitive = false;

		transaction.begin ((obj, res) => {
			try {
				transaction.end (res);
			} catch (Error e) {
				warning (e.message);
				on_toast (new Adw.Toast (e.message) { timeout = 0 });
			} finally {
				this.sensitive = true;
			}
		});
	}

	private async void transaction () throws Error {
		var publish_req = new Request () {
			method = "POST",
			url = "/api/v1/statuses",
			account = accounts.active
		};

		if (this.edit_status_id != null && this.edit_status_id != "") {
			publish_req = new Request () {
				method = "PUT",
				url = @"/api/v1/statuses/$(this.edit_status_id)",
				account = accounts.active
			};
		}

		publish_req.body_json (populate_json_body ());
		yield publish_req.await ();

		var parser = Network.get_parser_from_inputstream (publish_req.response_body);
		var node = network.parse_node (parser);
		var status = API.Status.from (node);
		debug (@"Published post with id $(status.id)");

		if (this.scheduled_id != null) {
			new Request.DELETE (@"/api/v1/scheduled_statuses/$scheduled_id")
				.with_account (accounts.active)
				.then (() => {
					if (cb != null) cb (status);
				})
				.exec ();
		} else if (cb != null) {
			cb (status);
		} else if (schedule_iso8601 != null) {
			app.refresh_scheduled_statuses ();
		}

		this.force_close ();
	}

	// This is used to check if something changed so we
	// can ask the user if they want to quit. In the old
	// composer, it used to check everything. This time,
	// let's just check the important ones only, since
	// asking when just changing trivial properties seems
	// annoying.
	private uint generate_unique_state () {
		GLib.StringBuilder builder = new GLib.StringBuilder (editor.buffer.text);
		builder.append (cw_button.active.to_string ());
		builder.append (cw_entry.text);

		if (attachmentsbin_component != null && editor.is_bottom_child (attachmentsbin_component) && !attachmentsbin_component.is_empty) {
			builder.append (string.joinv ("", attachmentsbin_component.get_all_media_ids ()));

			foreach (var meta in attachmentsbin_component.get_all_metadata ()) {
				builder.append (meta.id);
				builder.append (meta.description);
				builder.append (meta.focus);
			}
		} else {
			builder.append ("none");
		}

		if (polls_component != null && editor.is_bottom_child (polls_component) && polls_component.is_valid && polls_component.has_rows) {
			builder.append (string.joinv ("", polls_component.get_all_options ()));
			builder.append (polls_component.multiple_choice.to_string ());
			builder.append (polls_component.hide_totals.to_string ());
			builder.append (polls_component.expires_in.to_string ());
		} else {
			builder.append ("none");
		}

		return GLib.str_hash (builder.str);
	}

	private bool state_changed () {
		if (unique_state == 0) return false;
		return unique_state != generate_unique_state ();
	}

	private void on_exit () {
		if (state_changed ()) {
			app.question.begin (
				// translators: Dialog title when closing the composer
				{_("Discard Post?"), false},
				{_("Your progress will be lost."), false},
				this,
				{ { _("Discard"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) this.force_close ();
				}
			);
		} else {
			this.force_close ();
		}
	}
}
