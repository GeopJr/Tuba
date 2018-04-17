using Gtk;

public class Tootle.MainWindow: Gtk.Window {

    HeaderBar header;
    Stack stack;
    AccountsButton accounts;
    Granite.Widgets.ModeButton mode;
    Spinner spinner;
    Button button_toot;
    
    public HomeView home = new HomeView ();
    public LocalView feed_local = new LocalView ();
    public FederatedView feed_federated = new FederatedView ();
    public NotificationsView notifications = new NotificationsView ();

    public MainWindow (Gtk.Application application) {
         Object (application: application,
         icon_name: "com.github.bleakgrey.tootle",
            title: "Tootle",
            resizable: true
        );
        set_titlebar (header);
        window_position = WindowPosition.CENTER;
        
        AccountManager.instance.changed_current.connect(on_account_changed);
    }

    construct {
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/bleakgrey/tootle/Application.css");
        StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        stack = new Stack();
        stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        stack.show ();
        stack.set_size_request (400, 500);

        spinner = new Spinner ();
        spinner.active = true;

        accounts = new AccountsButton ();
		
		button_toot = new Button ();
        button_toot.tooltip_text = "Toot";
        button_toot.image = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_toot.clicked.connect (() => {
            TootDialog.open (this);
        });

        mode = new Granite.Widgets.ModeButton ();
        mode.get_style_context ().add_class ("mode");
        mode.mode_changed.connect(widget => {
            stack.set_visible_child_name(widget.tooltip_text);
        });
        
        header = new HeaderBar ();
        header.show_close_button = true;
        header.pack_start (button_toot);
        header.custom_title = mode;

        header.pack_end (accounts);
        header.pack_end (spinner);
        header.show ();
        
        mode.valign = Gtk.Align.FILL;

        add (stack);
        show_all ();
        
        NetManager.instance.started.connect (() => spinner.show ());
        NetManager.instance.finished.connect (() => spinner.hide ());
    }
    
    private void on_account_changed(Account? account){
        mode.hide ();
        button_toot.hide ();
        accounts.hide ();
        stack.forall (widget => stack.remove (widget));
    
        if(account == null)
            show_setup_views ();
        else
            show_main_views ();
    }
    
    private void show_setup_views (){
        var add_account = new AddAccountView ();
        stack.add_named (add_account, add_account.get_name ());
    }
    
    private void show_main_views (){
        mode.clear_children ();
        add_view (home);
        add_view (notifications);
        add_view (feed_local);
        add_view (feed_federated);
        mode.set_active (0);
        mode.show ();
        button_toot.show ();
        accounts.show ();
    }
    
    private void add_view (AbstractView view) {
        if (view.show_in_header){
            var img = new Gtk.Image.from_icon_name(view.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
            img.tooltip_text = view.get_name ();
            mode.append (img);
            view.image = img;
            
            stack.add_named(view, view.get_name ());
        }
    }

}
