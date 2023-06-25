using Gtk;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/preferences.ui")]
public class Tuba.Dialogs.Preferences : Adw.PreferencesWindow {

    [GtkChild] unowned Adw.ComboRow scheme_combo_row;
    [GtkChild] unowned Adw.ComboRow post_visibility_combo_row;
    [GtkChild] unowned Adw.ComboRow default_language_combo_row;
    [GtkChild] unowned Switch autostart;
    [GtkChild] unowned Switch work_in_background;
    [GtkChild] unowned SpinButton timeline_page_size;
    [GtkChild] unowned Switch live_updates;
    [GtkChild] unowned Switch public_live_updates;
    [GtkChild] unowned Switch show_spoilers;
    [GtkChild] unowned Switch hide_preview_cards;
    [GtkChild] unowned Switch larger_font_size;
    [GtkChild] unowned Switch larger_line_height;
    [GtkChild] unowned Switch strip_tracking;
	
	private bool lang_changed { get; set; default=false; }

	static construct {
		typeof (ColorSchemeListModel).ensure ();
	}

    construct {
        transient_for = app.main_window;

		post_visibility_combo_row.model = accounts.active.visibility_list;

        // Setup scheme combo row
        scheme_combo_row.selected = settings.get_enum ("color-scheme");

		uint default_visibility_index;
		if (accounts.active.visibility.has_key(settings.default_post_visibility) && accounts.active.visibility_list.find(accounts.active.visibility[settings.default_post_visibility], out default_visibility_index)) {
			post_visibility_combo_row.selected = default_visibility_index;
		} else {
			post_visibility_combo_row.selected = 0;
			on_post_visibility_changed ();
		}

		setup_languages_combo_row ();
		bind ();
        show ();
		close_request.connect(on_window_closed);
    }

    public static void open () {
        new Preferences ();
    }

	void bind () {
        //  settings.bind ("dark-theme", dark_theme, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("autostart", autostart, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("work-in-background", work_in_background, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("timeline-page-size", timeline_page_size.adjustment, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("live-updates", live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("public-live-updates", public_live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("show-spoilers", show_spoilers, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("hide-preview-cards", hide_preview_cards, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("larger-font-size", larger_font_size, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("larger-line-height", larger_line_height, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("strip-tracking", strip_tracking, "active", SettingsBindFlags.DEFAULT);

		post_visibility_combo_row.notify["selected-item"].connect(on_post_visibility_changed);

		ulong dlcr_id = 0;
		dlcr_id = default_language_combo_row.notify["selected-item"].connect(() => {
			lang_changed = true;
			default_language_combo_row.disconnect (dlcr_id);
		});
	}

	[GtkCallback]
	private void on_scheme_changed () {
		var selected_item = (ColorSchemeListItem) scheme_combo_row.selected_item;
		var style_manager = Adw.StyleManager.get_default ();

		style_manager.color_scheme = selected_item.adwaita_scheme;
		settings.color_scheme = selected_item.color_scheme;
	}

	private void on_post_visibility_changed () {
		settings.default_post_visibility = (string) ((InstanceAccount.Visibility) post_visibility_combo_row.selected_item).id;
	}

	private void setup_languages_combo_row () {
		var store = new GLib.ListStore (typeof (Locale));

		foreach (var locale in app.locales) {
			store.append (locale);
		}

		default_language_combo_row.list_factory = new BuilderListItemFactory.from_resource (null, Build.RESOURCES+"gtk/dropdown/language.ui");
		default_language_combo_row.model = store;

		var default_language = settings.default_language == "" ? "en" : settings.default_language;
		uint default_lang_index;
		if (store.find_with_equal_func(new Tuba.Locale(default_language, null, null), Tuba.Locale.compare, out default_lang_index)) {
			default_language_combo_row.selected = default_lang_index;
		}
	}

	private bool on_window_closed () {
		if (lang_changed) {
			var new_lang = ((Tuba.Locale) default_language_combo_row.selected_item).locale;
			if (settings.default_language != ((Tuba.Locale) default_language_combo_row.selected_item).locale) {

				new Request.PATCH ("/api/v1/accounts/update_credentials")
					.with_account (accounts.active)
					.with_form_data ("source[language]", new_lang)
					.then ((sess, msg, in_stream) => {
						var parser = Network.get_parser_from_inputstream(in_stream);
						var node = network.parse_node (parser);
						var updated = API.Account.from (node);

						settings.default_language = updated.source.language;
					})
					.exec ();
			}
		}

		return false;
	}
}

public class Tuba.ColorSchemeListModel : Object, ListModel {
	private Gee.ArrayList<ColorSchemeListItem> array = new Gee.ArrayList<ColorSchemeListItem> ();

	construct {
		array.add (new ColorSchemeListItem (SYSTEM));
		array.add (new ColorSchemeListItem (LIGHT));
		array.add (new ColorSchemeListItem (DARK));
	}

	public Object? get_item (uint position)
		requires (position < array.size)
	{
		return array.get ((int) position);
	}

	public Type get_item_type () {
		return typeof(ColorSchemeListItem);
	}

	public uint get_n_items () {
		return array.size;
	}

	public Object? get_object (uint position) {
		return get_item (position);
	}
}

public class Tuba.ColorSchemeListItem : Object {
	public ColorScheme color_scheme { get; construct; }
	public string name {
		owned get {
			return color_scheme.to_string ();
		}
	}
	public Adw.ColorScheme adwaita_scheme {
		get {
			return color_scheme.to_adwaita_scheme ();
		}
	}

	public ColorSchemeListItem (ColorScheme color_scheme) {
		Object (color_scheme: color_scheme);
	}
}