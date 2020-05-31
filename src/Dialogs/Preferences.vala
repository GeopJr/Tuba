using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/preferences.ui")]
public class Tootle.Dialogs.Preferences : Hdy.PreferencesWindow {

    [GtkChild]
    Switch dark_theme;
    [GtkChild]
    Switch autostart;
    [GtkChild]
    Switch work_in_background;
    [GtkChild]
    Hdy.ComboRow default_post_visibility;
    [GtkChild]
    SpinButton timeline_page_size;
    [GtkChild]
    SpinButton post_text_size;
    [GtkChild]
    Switch live_updates;
    [GtkChild]
    Switch public_live_updates;

    construct {
        transient_for = window;

        default_post_visibility.set_for_enum (typeof (API.Visibility), e => {
            var i = e.get_value ();
            var vis = API.Visibility.all ()[i];
            default_post_visibility.subtitle = vis.get_desc ();
            return vis.get_name ();
        });

		bind ();
        show ();
    }

    public static void open () {
        new Preferences ();
    }

	void bind () {
        settings.bind ("dark-theme", dark_theme, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("autostart", autostart, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("work-in-background", work_in_background, "active", SettingsBindFlags.DEFAULT);
        default_post_visibility.selected_index = (int) settings.default_post_visibility;
        default_post_visibility.notify["selected-index"].connect (p => {
            var i = default_post_visibility.selected_index;
            settings.default_post_visibility = (API.Visibility) i;
        });
        settings.bind ("timeline-page-size", timeline_page_size.adjustment, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("post-text-size", post_text_size.adjustment, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("live-updates", live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("public-live-updates", public_live_updates, "active", SettingsBindFlags.DEFAULT);
	}

}
