using Gtk;

public class Tootle.MainWindow: Gtk.Window {

    Tootle.HeaderBar header;
    public Stack primary_stack;
    public Stack secondary_stack;
    
    public HomeView home = new HomeView ();
    public LocalView feed_local = new LocalView ();
    public FederatedView feed_federated = new FederatedView ();
    public NotificationsView notifications = new NotificationsView ();

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/bleakgrey/tootle/Application.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        secondary_stack = new Stack();
        secondary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        secondary_stack.show ();
        secondary_stack.set_size_request (400, 500);
        primary_stack = new Stack();
        primary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        primary_stack.show ();
        primary_stack.add_named (secondary_stack, "modes");
        
        header = new Tootle.HeaderBar ();

        add (primary_stack);
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
        
        AccountManager.instance.switched.connect(on_account_switched);
    }
    
    private void on_account_switched(Account? account){
        secondary_stack.forall (widget => secondary_stack.remove (widget));
    
        if(account == null)
            show_setup_views ();
        else
            show_main_views ();
    }
    
    private void show_setup_views (){
        var add_account = new AddAccountView ();
        secondary_stack.add_named (add_account, add_account.get_name ());
        header.update (false, true);
    }
    
    private void show_main_views (){
        header.button_mode.clear_children ();
        add_view (home);
        add_view (notifications);
        add_view (feed_local);
        add_view (feed_federated);
        header.button_mode.set_active (0);
        header.update (true);
    }
    
    private void add_view (AbstractView view) {
        if (view.show_in_header){
            var img = new Gtk.Image.from_icon_name(view.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
            img.tooltip_text = view.get_name ();
            header.button_mode.append (img);
            view.image = img;
            secondary_stack.add_named(view, view.get_name ());
        }
    }
    
    public void open_secondary_view (Widget widget) {
        widget.show ();
        primary_stack.add_named (widget, "details");
        primary_stack.set_visible_child_name ("details");
        header.update (false);
    }

}
