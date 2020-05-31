using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/preferences.ui")]
public class Tootle.Dialogs.Preferences : Hdy.PreferencesWindow {

    [GtkChild]
    Hdy.ComboRow default_post_visibility;

    construct {
        transient_for = window;

        default_post_visibility.set_for_enum (typeof (API.Visibility), e => {
            var i = e.get_value ();
            var vis = API.Visibility.all ()[i];
            default_post_visibility.subtitle = vis.get_desc ();
            return vis.get_name ();
        });

        show ();
    }

    public static void open () {
        new Preferences ();
    }

}
