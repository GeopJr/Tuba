using Gtk;

public class Tootle.MainWindow: Gtk.Window {

    private weak SettingsManager settings;
    
    private Gtk.Overlay overlay;
    private Granite.Widgets.Toast toast;
    private Gtk.Grid grid;
    public Tootle.HeaderBar header;
    public Stack primary_stack;
    public Stack secondary_stack;

    construct {
        settings = Tootle.settings;
    
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/bleakgrey/tootle/app.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        settings.changed.connect (update_theme);
        update_theme ();

        toast = new Granite.Widgets.Toast ("");
        overlay = new Gtk.Overlay ();
        overlay.add_overlay (toast);
        secondary_stack = new Stack();
        secondary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        secondary_stack.show ();
        primary_stack = new Stack();
        primary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        primary_stack.show ();
        primary_stack.add_named (secondary_stack, "0");
        primary_stack.hexpand = true;
        primary_stack.vexpand = true;
        header = new Tootle.HeaderBar ();
        
        grid = new Gtk.Grid ();
        grid.set_size_request (400, 500);
        grid.attach (primary_stack, 0, 0, 1, 1);
        grid.attach (overlay, 0, 0, 1, 1);
        
        add (grid);
        show_all ();
    }
    
    public MainWindow (Gtk.Application application) {
         Object (application: application,
         icon_name: "com.github.bleakgrey.tootle",
            title: "Tootle",
            resizable: true
        );
        set_titlebar (header);
        window_position = WindowPosition.CENTER;
        
        Tootle.accounts.switched.connect(on_account_switched);
        Tootle.app.error.connect (on_error);
        Tootle.app.toast.connect (on_toast);
        Tootle.accounts.init ();
    }
    
    private void reset () {
        header.button_mode.clear_children ();
        secondary_stack.forall (widget => widget.destroy ());
    }
    
    private void on_account_switched(Account? account = Tootle.accounts.current){
        reset ();
        if(account == null)
            build_setup_view ();
        else
            build_main_view ();
    }
    
    private void build_setup_view (){
        var add_account = new AddAccountView ();
        secondary_stack.add_named (add_account, add_account.get_name ());
        header.update (false, true);
    }
    
    private void build_main_view (){
        add_header_view (new TimelineView ("home"));
        add_header_view (new NotificationsView ());
        add_header_view (new LocalView ());
        add_header_view (new FederatedView ());
        header.update (true);
    }
    
    private void add_header_view (AbstractView view) {
        var img = new Gtk.Image.from_icon_name(view.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
        img.tooltip_text = view.get_name ();
        header.button_mode.append (img);
        view.image = img;
        secondary_stack.add_named(view, view.get_name ());
        
        if (view is NotificationsView)
            img.pixel_size = 20; // For some reason Notifications icon is too small without this
    }
    
    public void open_view (Widget widget) {
        widget.show ();
        var i = int.parse (primary_stack.get_visible_child_name ());
        i++;
        primary_stack.add_named (widget, i.to_string ());
        primary_stack.set_visible_child_name (i.to_string ());
        header.update (false);
    }
    
    private void on_toast (string msg){
        toast.title = msg;
        toast.send_notification ();
    }
    
    private void on_error (string title, string msg){
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (title, msg, "dialog-warning");
        message_dialog.transient_for = this;
        message_dialog.run ();
        message_dialog.destroy ();
    }
    
    public override bool delete_event (Gdk.EventAny event) {
        this.destroy.connect (() => {
            if (!Tootle.settings.always_online)
                Tootle.app.remove_window (Tootle.window_dummy);
            Tootle.window = null;
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

}
