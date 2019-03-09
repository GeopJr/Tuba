using Gtk;

public class Tootle.MainWindow: Gtk.Window {

    private Overlay overlay;
    private Granite.Widgets.Toast toast;
    private Grid grid;
    private Stack primary_stack;
    private Stack secondary_stack;

    public HeaderBar header;
    public Granite.Widgets.ModeButton button_mode;
    private AccountsButton button_accounts;
    private Spinner spinner;
    private Button button_toot;
    private Button button_back;

    public HomeView home = new HomeView ();
    public NotificationsView notifications = new NotificationsView ();
    public LocalView local = new LocalView ();
    public FederatedView federated = new FederatedView ();

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/bleakgrey/tootle/app.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        settings.changed.connect (update_theme);
        update_theme ();

        secondary_stack = new Stack();
        secondary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        secondary_stack.show ();
        primary_stack = new Stack();
        primary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        primary_stack.show ();
        primary_stack.add_named (secondary_stack, "0");
        primary_stack.hexpand = true;
        primary_stack.vexpand = true;

        spinner = new Spinner ();
        spinner.active = true;

        button_accounts = new AccountsButton ();

        button_back = new Button ();
        button_back.valign = Align.CENTER;
        button_back.label = _("Back");
        button_back.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
        button_back.clicked.connect (() => back ());
        Desktop.set_hotkey_tooltip (button_back, null, app.ACCEL_BACK);

        button_toot = new Button ();
        button_toot.valign = Align.CENTER;
        button_toot.image = new Image.from_icon_name ("document-edit-symbolic", IconSize.LARGE_TOOLBAR);
        button_toot.clicked.connect (() => PostDialog.open ());
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
        grid.attach (primary_stack, 0, 0, 1, 1);

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
        button_press_event.connect ((event) => {
            if (event.button == 8) {
                back ();
                return true;
            }
            return false;
        });
    }

    private void add_header_view (AbstractView view, string[] accelerators, int32 num) {
        var img = new Image.from_icon_name (view.get_icon (), IconSize.LARGE_TOOLBAR);
        Desktop.set_hotkey_tooltip (img, view.get_name (), accelerators);
        button_mode.append (img);
        view.image = img;
        secondary_stack.add_named (view, num.to_string ());

        if (view is NotificationsView)
            img.pixel_size = 20; // For some reason Notifications icon is too small without this
    }

    public int get_visible_id () {
        return int.parse (primary_stack.get_visible_child_name ());
    }

    public void open_view (AbstractView widget) {
        var i = get_visible_id ();
        i++;
        widget.stack_pos = i;
        widget.show ();
        primary_stack.add_named (widget, i.to_string ());
        primary_stack.set_visible_child_name (i.to_string ());
        update_header ();
    }

    public void back () {
        var i = get_visible_id ();
        if (i == 0)
            return;

        var child = primary_stack.get_child_by_name (i.to_string ());
        primary_stack.set_visible_child_name ((i-1).to_string ());
        child.destroy ();
        update_header ();
    }

    public void reopen_view (int view_id) {
        var i = get_visible_id ();
        while (i != view_id && view_id != 0) {
            back ();
            i = get_visible_id ();
        }
    }

    public override bool delete_event (Gdk.EventAny event) {
        this.destroy.connect (() => {
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
        var visible = secondary_stack.get_visible_child () as AbstractView;
        visible.current = false;

        secondary_stack.set_visible_child_name (button_mode.selected.to_string ());

        visible = secondary_stack.get_visible_child () as AbstractView;
        visible.current = true;
        visible.on_set_current ();
    }

}
