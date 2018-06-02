using Gtk;

public class Tootle.AccountsButton : Gtk.MenuButton{

    const int AVATAR_SIZE = 24;
    Granite.Widgets.Avatar avatar;
    Gtk.Grid grid;
    Gtk.Popover menu;
    Gtk.ListBox list;
    Gtk.ModelButton item_settings;
    Gtk.ModelButton item_refresh;
    Gtk.ModelButton item_search;
    Gtk.ModelButton item_favs;

    private class AccountView : Gtk.ListBoxRow{
    
        private Gtk.Grid grid;
        public Gtk.Label display_name;
        public Gtk.Label instance;
        public Gtk.Button button;
        public int id = -1;
        
        construct {
            can_default = false;
            
            grid = new Gtk.Grid ();
            grid.margin = 6;
            grid.margin_start = 14;
        
            display_name = new Gtk.Label ("");
            display_name.hexpand = true;
            display_name.halign = Gtk.Align.START;
            display_name.use_markup = true;
            instance = new Gtk.Label ("");
            instance.halign = Gtk.Align.START;
            button = new Gtk.Button.from_icon_name ("close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            button.receives_default = false;
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
            
            grid.attach(display_name, 1, 0, 1, 1);
            grid.attach(instance, 1, 1, 1, 1);
            grid.attach(button, 2, 0, 2, 2);
            add (grid);
            show_all ();
        }
    
        public AccountView (){
            button.clicked.connect (() => accounts.remove (id));
        }
    
    }

    construct{
        avatar = new Granite.Widgets.Avatar.with_default_icon (AVATAR_SIZE);
        avatar.button_press_event.connect(event => {
            return false;
        });
    
        list = new Gtk.ListBox ();
    
        var item_separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        item_separator.hexpand = true;
    
        item_refresh = new Gtk.ModelButton ();  
        item_refresh.text = _("Refresh");
        item_refresh.clicked.connect (() => app.refresh ());
    
        item_favs = new Gtk.ModelButton ();  
        item_favs.text = _("Favorites");
        item_favs.clicked.connect (() => window.open_view (new FavoritesView ()));
    
        item_search = new Gtk.ModelButton ();  
        item_search.text = _("Search");
        item_search.clicked.connect (() => window.open_view (new SearchView ()));
    
        item_settings = new Gtk.ModelButton ();  
        item_settings.text = _("Settings");
        item_settings.clicked.connect (() => SettingsDialog.open ());
    
        grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.width_request = 200;
        grid.attach(list, 0, 1, 1, 1);
        grid.attach(item_separator, 0, 3, 1, 1);
        grid.attach(item_favs, 0, 4, 1, 1);
        grid.attach(new Gtk.Separator (Gtk.Orientation.HORIZONTAL), 0, 5, 1, 1);
        grid.attach(item_refresh, 0, 6, 1, 1);
        grid.attach(item_search, 0, 7, 1, 1);
        grid.attach(item_settings, 0, 8, 1, 1);
        grid.show_all ();
        
        menu = new Gtk.Popover (null);
        menu.add (grid);

        get_style_context ().add_class ("button_avatar");
        popover = menu;
        add(avatar);
        show_all ();
        
        accounts.updated.connect (accounts_updated);
        accounts.switched.connect (account_switched);
        list.row_activated.connect (row => {
            var widget = row as AccountView;
            if (widget.id == -1) {
                NewAccountDialog.open ();
                return;
            }
            if (widget.id == Tootle.settings.current_account)
                return;
            else
                accounts.switch_account (widget.id);
        });
    }
    
    private void accounts_updated (GenericArray<InstanceAccount> accounts) {
        list.forall (widget => widget.destroy ());
        int i = -1;
        accounts.foreach (account => {
            i++;
            var widget = new AccountView ();
            widget.id = i;
            widget.display_name.label = "<b>@"+account.username+"</b>";
            widget.instance.label = account.get_pretty_instance ();
            list.add (widget);
        });
        
        var add_account = new AccountView ();
        add_account.display_name.label = _("<b>New Account</b>");
        add_account.instance.label = _("Click to add");
        add_account.button.hide ();
        list.add (add_account);
        update_selection ();
    }
    
    private void account_switched (Account? account) {
        if (account == null)
            avatar.show_default (AVATAR_SIZE);
        else
            network.load_avatar (account.avatar, avatar, get_avatar_size ());
    }
    
    private void update_selection () {
        var id = Tootle.settings.current_account;
        var row = list.get_row_at_index (id);
        if (row != null)
            list.select_row (row);
    }

    public int get_avatar_size () {
        return AVATAR_SIZE * get_style_context ().get_scale ();
    }

    public AccountsButton() {
        account_switched (accounts.current);
    }

}
