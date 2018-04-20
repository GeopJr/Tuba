using Gtk;

public class Tootle.MainWindow: Gtk.Window {

    HeaderBar header;
    Stack primary_stack;
    Stack secondary_stack;
    AccountsButton button_accounts;
    Granite.Widgets.ModeButton button_mode;
    Spinner spinner;
    Button button_toot;
    Button button_back;
    
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

        secondary_stack = new Stack();
        secondary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        secondary_stack.show ();
        secondary_stack.set_size_request (400, 500);
        primary_stack = new Stack();
        primary_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;
        primary_stack.show ();
        primary_stack.add_named (secondary_stack, "modes");

        spinner = new Spinner ();
        spinner.active = true;

        button_accounts = new AccountsButton ();
		
		button_back = new Button ();
		button_back.label = _("Back");
		button_back.get_style_context ().add_class (Granite.STYLE_CLASS_BACK_BUTTON);
		button_back.clicked.connect (() => {
		    primary_stack.set_visible_child_name ("modes");
		    var child = primary_stack.get_child_by_name ("details");
		    child.destroy ();
		    update_header (true);
		});
		
		button_toot = new Button ();
        button_toot.tooltip_text = "Toot";
        button_toot.image = new Gtk.Image.from_icon_name ("edit-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_toot.clicked.connect (() => {
            PostDialog.open (this);
        });

        button_mode = new Granite.Widgets.ModeButton ();
        button_mode.get_style_context ().add_class ("mode");
        button_mode.mode_changed.connect(widget => {
            secondary_stack.set_visible_child_name(widget.tooltip_text);
        });
        button_mode.show ();
        
        header = new HeaderBar ();
        header.custom_title = button_mode;
        header.show_close_button = true;
        header.pack_start (button_back);
        header.pack_start (button_toot);
        header.pack_end (button_accounts);
        header.pack_end (spinner);
        button_mode.valign = Gtk.Align.FILL;
        header.show ();

        add (primary_stack);
        show_all ();
        
        NetManager.instance.started.connect (() => spinner.show ());
        NetManager.instance.finished.connect (() => spinner.hide ());
    }
    
    private void on_account_changed(Account? account){
        secondary_stack.forall (widget => secondary_stack.remove (widget));
    
        if(account == null)
            show_setup_views ();
        else
            show_main_views ();
    }
    
    private void update_header (bool primary_mode, bool hide_all = false){
        if (hide_all){
            button_mode.opacity = 0;
            button_mode.sensitive = false;
            button_toot.hide ();
            button_back.hide ();
            button_accounts.hide ();
            return;
        }
        button_mode.opacity = primary_mode ? 1 : 0;
        button_mode.sensitive = primary_mode ? true : false;
        button_toot.set_visible (primary_mode);
        button_back.set_visible (!primary_mode);
        button_accounts.set_visible (true);
    }
    
    private void show_setup_views (){
        var add_account = new AddAccountView ();
        secondary_stack.add_named (add_account, add_account.get_name ());
        update_header (false, true);
    }
    
    private void show_main_views (){
        button_mode.clear_children ();
        add_view (home);
        add_view (notifications);
        add_view (feed_local);
        add_view (feed_federated);
        button_mode.set_active (0);
        update_header (true);
    }
    
    private void add_view (AbstractView view) {
        if (view.show_in_header){
            var img = new Gtk.Image.from_icon_name(view.get_icon (), Gtk.IconSize.LARGE_TOOLBAR);
            img.tooltip_text = view.get_name ();
            button_mode.append (img);
            view.image = img;
            secondary_stack.add_named(view, view.get_name ());
        }
    }
    
    public void open_secondary_view (Widget widget) {
        widget.show ();
        primary_stack.add_named (widget, "details");
        primary_stack.set_visible_child_name ("details");
        update_header (false);
    }

}
