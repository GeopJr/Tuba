using Gtk;

public class Tootle.AccountsButton : Gtk.MenuButton{

    Granite.Widgets.Avatar avatar;
    Gtk.Grid grid;
    Gtk.Popover menu;
    AccountView default_account;
    Gtk.ModelButton item_settings;
    Gtk.ModelButton item_refresh;
    Gtk.ModelButton item_favs;

    private class AccountView : Gtk.Grid{
    
        public Gtk.Label display_name;
        public Gtk.Label user;
        public Gtk.Button logout;
    
        construct {
            margin = 6;
            margin_start = 14;
        
            display_name = new Gtk.Label ("<b>Anonymous</b>");
            display_name.hexpand = true;
            display_name.halign = Gtk.Align.START;
            display_name.use_markup = true;
            user = new Gtk.Label ("@error");
            user.halign = Gtk.Align.START;
            logout = new Gtk.Button.from_icon_name ("pane-hide-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            logout.receives_default = false;
            logout.tooltip_text = _("Log out");
            logout.clicked.connect (() => Tootle.accounts.logout ());
            show_all ();
            
            attach(display_name, 1, 0, 1, 1);
            attach(user, 1, 1, 1, 1);
            attach(logout, 2, 0, 2, 2);
        }
    
        public AccountView (){}
    
    }

    construct{
        avatar = new Granite.Widgets.Avatar.with_default_icon (24);
        avatar.button_press_event.connect(event => {
            return false;
        });
    
        default_account = new AccountView ();
    
        var item_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        item_separator.hexpand = true;
    
        item_refresh = new Gtk.ModelButton ();  
        item_refresh.text = _("Refresh");
        item_refresh.clicked.connect (() => Tootle.app.refresh ());
    
        item_favs = new Gtk.ModelButton ();  
        item_favs.text = _("Favorites");
        item_favs.clicked.connect (() => Tootle.window.open_view (new FavoritesView ()));
    
        item_settings = new Gtk.ModelButton ();  
        item_settings.text = _("Settings");
    
        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 200;
        grid.attach(default_account, 0, 1, 1, 1);
        grid.attach(item_separator, 0, 2, 1, 1);
        grid.attach(item_favs, 0, 4, 1, 1);
        grid.attach(new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 5, 1, 1);
        grid.attach(item_refresh, 0, 6, 1, 1);
        grid.attach(item_settings, 0, 7, 1, 1);
        grid.show_all ();
        
        menu = new Gtk.Popover (null);
        menu.add (grid);

        get_style_context ().add_class ("button_avatar");
        popover = menu;
        add(avatar);
        show_all ();
        
        Tootle.accounts.switched.connect (account => {
            if (account != null){
                Tootle.cache.load_avatar (account.avatar, avatar, 24);
                default_account.display_name.label = "<b>"+account.display_name+"</b>";
                default_account.user.label = "@"+account.username;
            }
        });
    }

    public AccountsButton(){
        Object();
    }

}
