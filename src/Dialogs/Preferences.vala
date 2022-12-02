using Gtk;

[GtkTemplate (ui = "/dev/geopjr/tooth/ui/dialogs/preferences.ui")]
public class Tooth.Dialogs.Preferences : Adw.PreferencesWindow {

    //  [GtkChild] unowned Switch dark_theme;
    [GtkChild] unowned Switch autostart;
    [GtkChild] unowned Switch work_in_background;
    [GtkChild] unowned SpinButton timeline_page_size;
    [GtkChild] unowned SpinButton post_text_size;
    [GtkChild] unowned Switch live_updates;
    [GtkChild] unowned Switch public_live_updates;
    [GtkChild] unowned Switch show_spoilers;

    construct {
        transient_for = app.main_window;

		// TODO: default_post_visibility options
        // default_post_visibility.set_for_enum (typeof (API.Visibility), e => {
        //     var i = e.get_value ();
        //     var vis = API.Visibility.all ()[i];
        //     default_post_visibility.subtitle = vis.get_desc ();
        //     return vis.get_name ();
        // });

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

}
