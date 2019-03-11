using Gtk;

public class Tootle.Widgets.AccountsButton : MenuButton {

    const int AVATAR_SIZE = 24;
    Granite.Widgets.Avatar avatar;
    Grid grid;
    Popover menu;
    ListBox list;
    ModelButton item_settings;
    ModelButton item_refresh;
    ModelButton item_search;
    ModelButton item_favs;
    ModelButton item_direct;
    ModelButton item_watchlist;

    private class AccountItemView : ListBoxRow {

        private Grid grid;
        public Label display_name;
        public Label instance;
        public Button button;
        public int id = -1;

        construct {
            can_default = false;

            grid = new Grid ();
            grid.margin = 6;
            grid.margin_start = 14;

            display_name = new Label ("");
            display_name.hexpand = true;
            display_name.halign = Align.START;
            display_name.use_markup = true;
            instance = new Label ("");
            instance.halign = Align.START;
            button = new Button.from_icon_name ("window-close-symbolic", IconSize.SMALL_TOOLBAR);
            button.receives_default = false;
            button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

            grid.attach (display_name, 1, 0, 1, 1);
            grid.attach (instance, 1, 1, 1, 1);
            grid.attach (button, 2, 0, 2, 2);
            add (grid);
            show_all ();
        }

        public AccountItemView (){
            button.clicked.connect (() => accounts.remove (id));
        }

    }

    construct{
        avatar = new Granite.Widgets.Avatar.with_default_icon (AVATAR_SIZE);
        list = new ListBox ();

        var item_separator = new Separator (Orientation.HORIZONTAL);
        item_separator.hexpand = true;

        item_refresh = new ModelButton ();
        item_refresh.text = _("Refresh");
        item_refresh.clicked.connect (() => app.refresh ());
        Desktop.set_hotkey_tooltip (item_refresh, null, app.ACCEL_REFRESH);

        item_favs = new ModelButton ();
        item_favs.text = _("Favorites");
        item_favs.clicked.connect (() => window.open_view (new Views.Favorites ()));

        item_direct = new ModelButton ();
        item_direct.text = _("Direct Messages");
        item_direct.clicked.connect (() => window.open_view (new Views.Direct ()));

        item_search = new ModelButton ();
        item_search.text = _("Search");
        item_search.clicked.connect (() => window.open_view (new Views.Search ()));

        item_watchlist = new ModelButton ();
        item_watchlist.text = _("Watchlist");
        item_watchlist.clicked.connect (() => Dialogs.WatchlistEditor.open ());

        item_settings = new ModelButton ();
        item_settings.text = _("Settings");
        item_settings.clicked.connect (() => Dialogs.Preferences.open ());

        grid = new Grid ();
        grid.orientation = Orientation.VERTICAL;
        grid.width_request = 200;
        grid.attach (list, 0, 1, 1, 1);
        grid.attach (item_separator, 0, 3, 1, 1);
        grid.attach (item_favs, 0, 4, 1, 1);
        grid.attach (item_direct, 0, 5, 1, 1);
        grid.attach (new Separator (Orientation.HORIZONTAL), 0, 6, 1, 1);
        grid.attach (item_refresh, 0, 7, 1, 1);
        grid.attach (item_search, 0, 8, 1, 1);
        grid.attach (item_watchlist, 0, 9, 1, 1);
        grid.attach (item_settings, 0, 10, 1, 1);
        grid.show_all ();

        menu = new Popover (null);
        menu.add (grid);

        get_style_context ().add_class ("button_avatar");
        popover = menu;
        add (avatar);
        show_all ();

        accounts.updated.connect (accounts_updated);
        accounts.switched.connect (account_switched);
        list.row_activated.connect (row => {
            var widget = row as AccountItemView;
            if (widget.id == -1) {
                Dialogs.NewAccount.open ();
                return;
            }
            if (widget.id == settings.current_account)
                Views.Profile.open_from_id (accounts.current.id);
            else
                accounts.switch_account (widget.id);

            menu.popdown ();
        });
    }

    private void accounts_updated (GenericArray<InstanceAccount> accounts) {
        list.forall (widget => widget.destroy ());
        int i = -1;
        accounts.foreach (account => {
            i++;
            var widget = new AccountItemView ();
            widget.id = i;
            widget.display_name.label = "<b>@"+account.username+"</b>";
            widget.instance.label = account.get_pretty_instance ();
            list.add (widget);
        });

        var add_account = new AccountItemView ();
        add_account.display_name.label = _("<b>New Account</b>");
        add_account.instance.label = _("Click to add");
        add_account.button.hide ();
        list.add (add_account);
        update_selection ();
    }

    private void account_switched (API.Account? account) {
        if (account == null)
            avatar.show_default (AVATAR_SIZE);
        else
            network.load_avatar (account.avatar, avatar, get_avatar_size ());
    }

    private void update_selection () {
        var id = settings.current_account;
        var row = list.get_row_at_index (id);
        if (row != null)
            list.select_row (row);
    }

    public int get_avatar_size () {
        return AVATAR_SIZE * get_style_context ().get_scale ();
    }

    public AccountsButton () {
        account_switched (accounts.current);
    }

}
