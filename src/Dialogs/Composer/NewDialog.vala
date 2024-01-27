[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/new_composer.ui")]
public class Tuba.Dialogs.NewCompose : Adw.Window {
	[GtkChild] private unowned Gtk.Label counter_label;
	[GtkChild] private unowned Gtk.Button post_btn;
	[GtkChild] private unowned Gtk.Box btns_box;
	[GtkChild] private unowned Gtk.Box dropdowns_box;
	[GtkChild] private unowned Gtk.Grid grid;

	[GtkChild] private unowned Gtk.Box status_box;
	[GtkChild] private unowned Gtk.Box main_box;

	[GtkChild] private unowned Gtk.MenuButton native_emojis_button;
	[GtkChild] private unowned Gtk.MenuButton custom_emojis_button;

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
			} else {
				post_layout_child.column = 2;
				post_layout_child.row = 0;
				post_layout_child.row_span = 2;

				counter_layout_child.row = 1;
				counter_layout_child.column = 1;

				btns_layout_child.column_span = 2;

				counter_label.margin_end = 0;
				counter_label.margin_start = 12;
			}

			_is_narrow = value;
		}
	}
	protected int64 char_limit { get; set; default = 500; }

	private int64 _remaining_chars = 500;
	protected int64 remaining_chars {
		get {
			return _remaining_chars;
		}
		set {
			_remaining_chars = value;
			counter_label.label = @"$value / $char_limit";

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

		if (accounts.active.instance_emojis?.size > 0) {
			var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
			custom_emojis_button.popover = custom_emoji_picker;
			custom_emoji_picker.emoji_picked.connect (editor.insert_string_at_cursor);
		}
	}

	private Componenets.Editor editor;
	private void install_editor () {
		editor = new Dialogs.Componenets.Editor ();
		main_box.append (editor);

		editor.notify["char-count"].connect (update_remaining_chars);
	}

	private void update_remaining_chars () {
		int64 res = char_limit;
		res -= editor.char_count;
		remaining_chars = res;
	}

	protected Gtk.DropDown visibility_button;
	protected Gtk.DropDown language_button;

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

		dropdowns_box.append (visibility_button);
	}

	private void install_languages (string? locale_iso = null) {
		language_button = new Gtk.DropDown (app.app_locales.list_store, null) {
			expression = new Gtk.PropertyExpression (typeof (Tuba.Locales.Locale), null, "name"),
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
					new Tuba.Locales.Locale (locale_iso, null, null),
					Tuba.Locales.Locale.compare,
					out default_lang_index
				)
			) {
				language_button.selected = default_lang_index;
			}
		}

		dropdowns_box.append (language_button);
	}

	construct {
		var condition = new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			400, Adw.LengthUnit.SP
		);
		var breakpoint = new Adw.Breakpoint (condition);
		breakpoint.add_setter (this, "is-narrow", true);
		add_breakpoint (breakpoint);

		var char_limit_api = accounts.active.instance_info.compat_status_max_characters;
		if (char_limit_api > 0)
			char_limit = char_limit_api;

		install_editor ();
		install_emoji_pickers ();
		install_visibility ();
		install_languages ();

		update_remaining_chars ();
		transient_for = app.main_window;
	}

	public NewCompose (API.Status template = new API.Status.empty ()) {
		Object ();
		present ();
	}
}