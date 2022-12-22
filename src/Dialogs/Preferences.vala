using Gtk;

[GtkTemplate (ui = "/dev/geopjr/tooth/ui/dialogs/preferences.ui")]
public class Tooth.Dialogs.Preferences : Adw.PreferencesWindow {

    [GtkChild] unowned Adw.ComboRow scheme_combo_row;
    [GtkChild] unowned Switch autostart;
    [GtkChild] unowned Switch work_in_background;
    [GtkChild] unowned SpinButton timeline_page_size;
    [GtkChild] unowned SpinButton post_text_size;
    [GtkChild] unowned Switch live_updates;
    [GtkChild] unowned Switch public_live_updates;
    [GtkChild] unowned Switch show_spoilers;

 	static construct {
		typeof (ColorSchemeListModel).ensure ();
	}

    construct {
        transient_for = app.main_window;

		// TODO: default_post_visibility options
        // default_post_visibility.set_for_enum (typeof (API.Visibility), e => {
        //     var i = e.get_value ();
        //     var vis = API.Visibility.all ()[i];
        //     default_post_visibility.subtitle = vis.get_desc ();
        //     return vis.get_name ();
        // });

        // Setup scheme combo row
        scheme_combo_row.selected = settings.get_enum ("color-scheme");

		bind ();
        show ();
    }

    public static void open () {
        new Preferences ();
    }

	void bind () {
        //  settings.bind ("dark-theme", dark_theme, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("autostart", autostart, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("work-in-background", work_in_background, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("timeline-page-size", timeline_page_size.adjustment, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("post-text-size", post_text_size.adjustment, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("live-updates", live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("public-live-updates", public_live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("show-spoilers", show_spoilers, "active", SettingsBindFlags.DEFAULT);
	}

	[GtkCallback]
	private void on_scheme_changed () {
		var selected_item = (ColorSchemeListItem) scheme_combo_row.selected_item;
		var style_manager = Adw.StyleManager.get_default ();

		style_manager.color_scheme = selected_item.adwaita_scheme;
		settings.color_scheme = selected_item.color_scheme;
	}
}

public class Tooth.ColorSchemeListModel : Object, ListModel {
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

public class Tooth.ColorSchemeListItem : Object {
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