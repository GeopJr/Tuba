using Gtk;
using Tootle;

public class Tootle.SettingsDialog : Gtk.Dialog {

    private static SettingsDialog dialog;

    private SettingsSwitch switch_notifications;
    private SettingsSwitch switch_watcher;
    private SettingsSwitch switch_stream;
    private SettingsSwitch switch_stream_public;
    private Gtk.Grid grid;

    public SettingsDialog () {
        border_width = 6;
        deletable = false;
        resizable = false;
        title = _("Settings");
        transient_for = window;
        
        int i = 0;
        grid = new Gtk.Grid ();
        
        switch_watcher = new SettingsSwitch ("always-online");
        switch_notifications = new SettingsSwitch ("notifications");
        switch_notifications.state_set.connect (state => {
            switch_watcher.sensitive = state;
            return false;
        });
        switch_stream = new SettingsSwitch ("live-updates");
        switch_stream_public = new SettingsSwitch ("live-updates-public");
        switch_stream.state_set.connect (state => {
            switch_stream_public.sensitive = state;
            return false;
        });
        
        grid.attach (new Granite.HeaderLabel (_("Appearance")), 0, i++, 2, 1);
        grid.attach (new SettingsLabel (_("Dark theme:")), 0, i);
        grid.attach (new SettingsSwitch ("dark-theme"), 1, i++);
        
        grid.attach (new Granite.HeaderLabel (_("Timelines")), 0, i++, 2, 1);
        grid.attach (new SettingsLabel (_("Real-time updates:")), 0, i);
        grid.attach (switch_stream, 1, i++);
        grid.attach (new SettingsLabel (_("Update public timelines:")), 0, i);
        grid.attach (switch_stream_public, 1, i++);
        
        // grid.attach (new Granite.HeaderLabel (_("Caching")), 0, i++, 2, 1);
        // grid.attach (new SettingsLabel (_("Use cache:")), 0, i);
        // grid.attach (new SettingsSwitch ("cache"), 1, i++);
        // grid.attach (new SettingsLabel (_("Max cache size (MB):")), 0, i);
        // var cache_size = new Gtk.SpinButton.with_range (16, 256, 1);
        // settings.schema.bind ("cache-size", cache_size, "value", SettingsBindFlags.DEFAULT);
        // grid.attach (cache_size, 1, i++);
        
        grid.attach (new Granite.HeaderLabel (_("Notifications")), 0, i++, 2, 1);
        grid.attach (new SettingsLabel (_("Display notifications:")), 0, i);
        grid.attach (switch_notifications, 1, i++);
        grid.attach (new SettingsLabel (_("Always receive notifications:")), 0, i);
        grid.attach (switch_watcher, 1, i++);
        
        var content = get_content_area () as Gtk.Box;
        content.pack_start (grid, false, false, 0);
        
        var close = add_button (_("_Close"), Gtk.ResponseType.CLOSE) as Gtk.Button;
        close.clicked.connect (() => {
            destroy ();
            dialog = null;
        });
        
        show_all ();
    }

    public static void open () {
        if (dialog == null)
            dialog = new SettingsDialog ();
    }

    protected class SettingsLabel : Gtk.Label {
        public SettingsLabel (string text) {
            label = text;
            halign = Gtk.Align.END;
            margin_start = 12;
            margin_end = 12;
        }
    }

    protected class SettingsSwitch : Gtk.Switch {
        public SettingsSwitch (string setting) {
            halign = Gtk.Align.START;
            valign = Gtk.Align.CENTER;
            margin_bottom = 6;
            settings.schema.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
        }
    }

}
