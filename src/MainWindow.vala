using Gtk;

public class Tootle.MainWindow: Gtk.Window {
    
    private Overlay overlay;
    private Granite.Widgets.Toast toast;
    private Grid grid;
    private Stack primary_stack;
    private Stack secondary_stack;
    
    public HeaderBar header;
    private Granite.Widgets.ModeButton button_mode;
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
        button_back.label = _("Back");
        button_back.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
        button_back.clicked.connect (() => back ());
        
        button_toot = new Button ();
        button_toot.tooltip_text = _("Toot");
        button_toot.image = new Gtk.Image.from_icon_name ("document-edit-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_toot.clicked.connect (() => PostDialog.open ());

        button_mode = new Granite.Widgets.ModeButton ();
        button_mode.get_style_context ().add_class ("mode");
        button_mode.vexpand = true;
        button_mode.valign = Gtk.Align.FILL;
        button_mode.mode_changed.connect (widget => {
            secondary_stack.set_visible_child_name (widget.tooltip_text);
        });
        button_mode.show ();
        
        header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.title = "Tootle";
        header.custom_title = button_mode;
        header.pack_start (button_back);
        header.pack_start (button_toot);
        header.pack_end (button_accounts);
        header.pack_end (spinner);
        header.show_all ();
        set_titlebar (header);
        
        grid = new Gtk.Grid ();
        grid.attach (primary_stack, 0, 0, 1, 1);
        
        add_header_view (home);
        add_header_view (notifications);
        add_header_view (local);
        add_header_view (federated);
        button_mode.set_active (0);
        
        toast = new Granite.Widgets.Toast ("");
        overlay = new Gtk.Overlay ();
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
        update_header ();
        
        app.toast.connect (on_toast);
        network.started.connect (() => spinner.show ());
        network.finished.connect (() => spinner.hide ());
        accounts.updated (accounts.saved_accounts);
    }
    
    private void add_header_view (AbstractView view) {
        var img = new Gtk.Image.from_icon_name (view.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
        img.tooltip_text = view.get_name ();
        button_mode.append (img);
        view.image = img;
        secondary_stack.add_named (view, view.get_name ());
        
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
    
    private void on_toast (string msg){
        toast.title = msg;
        toast.send_notification ();
    }
    
    public override bool delete_event (Gdk.EventAny event) {
        this.destroy.connect (() => {
            if (!settings.always_online || accounts.is_empty ())
                app.remove_window (window_dummy);
            window = null;
        });
        return false;
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

}
