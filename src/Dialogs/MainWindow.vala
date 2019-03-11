using Gtk;
using Gdk;

public class Tootle.Dialogs.MainWindow: Gtk.Window, ISavedWindow {

    private Overlay overlay;
    private Granite.Widgets.Toast toast;
    private Grid grid;
    private Stack view_stack;
    private Stack timeline_stack;

    public HeaderBar header;
    public Granite.Widgets.ModeButton button_mode;
    private Widgets.AccountsButton button_accounts;
    private Spinner spinner;
    private Button button_toot;
    private Button button_back;

    public Views.Home home = new Views.Home ();
    public Views.Notifications notifications = new Views.Notifications ();
    public Views.Local local = new Views.Local ();
    public Views.Federated federated = new Views.Federated ();

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/bleakgrey/tootle/app.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings.changed.connect (update_theme);
        update_theme ();

        timeline_stack = new Stack();
        timeline_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        timeline_stack.show ();
        view_stack = new Stack();
        view_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        view_stack.show ();
        view_stack.add_named (timeline_stack, "0");
        view_stack.hexpand = view_stack.vexpand = true;

        spinner = new Spinner ();
        spinner.active = true;

        button_accounts = new Widgets.AccountsButton ();

        button_back = new Button ();
        button_back.valign = Align.CENTER;
        button_back.label = _("Back");
        button_back.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
        button_back.clicked.connect (() => back ());
        Desktop.set_hotkey_tooltip (button_back, null, app.ACCEL_BACK);

        button_toot = new Button ();
        button_toot.valign = Align.CENTER;
        button_toot.image = new Image.from_icon_name ("document-edit-symbolic", IconSize.LARGE_TOOLBAR);
        button_toot.clicked.connect (() => Dialogs.Compose.open ());
        Desktop.set_hotkey_tooltip (button_toot, _("Toot"), app.ACCEL_NEW_POST);

        button_mode = new Granite.Widgets.ModeButton ();
        button_mode.get_style_context ().add_class ("mode");
        button_mode.vexpand = true;
        button_mode.valign = Align.FILL;
        button_mode.mode_changed.connect (on_mode_changed);
        button_mode.show ();

        header = new HeaderBar ();
        header.get_style_context ().add_class ("compact");
        header.show_close_button = true;
        header.title = _("Tootle");
        header.custom_title = button_mode;
        header.pack_start (button_back);
        header.pack_start (button_toot);
        header.pack_end (button_accounts);
        header.pack_end (spinner);
        header.show_all ();

        grid = new Grid ();
        grid.attach (view_stack, 0, 0, 1, 1);

        add_header_view (home, app.ACCEL_TIMELINE_0, 0);
        add_header_view (notifications, app.ACCEL_TIMELINE_1, 1);
        add_header_view (local, app.ACCEL_TIMELINE_2, 2);
        add_header_view (federated, app.ACCEL_TIMELINE_3, 3);
        button_mode.set_active (0);

        toast = new Granite.Widgets.Toast ("");
        overlay = new Overlay ();
        overlay.add_overlay (grid);
        overlay.add_overlay (toast);
        overlay.set_size_request (450, 600);
        add (overlay);

        restore_state ();
        show_all ();
    }

    public MainWindow (Gtk.Application _app) {
        application = _app;
        icon_name = "com.github.bleakgrey.tootle";
        resizable = true;
        window_position = WindowPosition.CENTER;
        set_titlebar (header);
        update_header ();

        app.toast.connect (on_toast);
        network.started.connect (() => spinner.show ());
        network.finished.connect (() => spinner.hide ());
        accounts.updated (accounts.saved_accounts);
        button_press_event.connect (on_button_press);
    }

    private bool on_button_press (EventButton ev) {
        if (ev.button == 8)
            return back ();
        return false;
    }

    private void add_header_view (Views.Abstract view, string[] accelerators, int32 num) {
        var img = new Image.from_icon_name (view.get_icon (), IconSize.LARGE_TOOLBAR);
        Desktop.set_hotkey_tooltip (img, view.get_name (), accelerators);
        button_mode.append (img);
        view.image = img;
        timeline_stack.add_named (view, num.to_string ());

        if (view is Views.Notifications)
            img.pixel_size = 20; // For some reason Notifications icon is too small without this
    }

    public int get_visible_id () {
        return int.parse (view_stack.get_visible_child_name ());
    }

    public bool open_view (Views.Abstract widget) {
        var i = get_visible_id ();
        i++;
        widget.stack_pos = i;
        widget.show ();
        view_stack.add_named (widget, i.to_string ());
        view_stack.set_visible_child_name (i.to_string ());
        update_header ();
        return true;
    }

    public bool back () {
        var i = get_visible_id ();
        if (i == 0)
            return false;

        var child = view_stack.get_child_by_name (i.to_string ());
        view_stack.set_visible_child_name ((i-1).to_string ());
        child.destroy ();
        update_header ();
        return true;
    }

    public void reopen_view (int view_id) {
        var i = get_visible_id ();
        while (i != view_id && view_id != 0) {
            back ();
            i = get_visible_id ();
        }
    }

    public override bool delete_event (Gdk.EventAny event) {
        destroy.connect (() => {
            if (!settings.always_online || accounts.is_empty ())
                app.remove_window (window_dummy);
            window = null;
        });
        return false;
    }

    public void switch_timeline (int32 timeline_no) {
        button_mode.set_active (timeline_no);
    }

    private void update_theme () {
        var provider = new Gtk.CssProvider ();
        var is_dark = settings.dark_theme;
        var theme = is_dark ? "dark" : "light";
        provider.load_from_resource ("/com/github/bleakgrey/tootle/%s.css".printf (theme));
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        Gtk.Settings.get_default ().gtk_application_prefer_dark_theme = is_dark;
    }

    private void update_header () {
        bool primary_mode = get_visible_id () == 0;
        button_mode.sensitive = primary_mode;
        button_mode.opacity = primary_mode ? 1 : 0; //Prevent HeaderBar height jitter
        button_toot.set_visible (primary_mode);
        button_back.set_visible (!primary_mode);
        button_accounts.set_visible (true);
    }

    private void on_toast (string msg){
        toast.title = msg;
        toast.send_notification ();
    }

    private void on_mode_changed (Widget widget) {
        var visible = timeline_stack.get_visible_child () as Views.Abstract;
        visible.current = false;

        timeline_stack.set_visible_child_name (button_mode.selected.to_string ());

        visible = timeline_stack.get_visible_child () as Views.Abstract;
        visible.current = true;
        visible.on_set_current ();
    }

}
