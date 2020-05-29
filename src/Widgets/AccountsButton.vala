using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button.ui")]
public class Tootle.Widgets.AccountsButton : Gtk.MenuButton, IAccountListener {

    [GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button_item.ui")]
    private class Item : Grid {
        [GtkChild]
        private Widgets.Avatar avatar;
        [GtkChild]
        private Label name;
        [GtkChild]
        private Label handle;
        [GtkChild]
        private Button profile;
        [GtkChild]
        private Button remove;

        public Item (InstanceAccount acc, AccountsButton _self) {
            avatar.url = acc.avatar;
            name.label = acc.display_name;
            handle.label = acc.handle;

            profile.clicked.connect (() => {
                Views.Profile.open_from_id (acc.id);
                _self.active = false;
            });

            remove.clicked.connect (() => {
                _self.active = false;
                accounts.remove (acc);
            });
        }

        public Item.add_new () {
            name.label = _("New Account");
            handle.label = _("Click to add");
            profile.destroy ();
            remove.destroy ();
        }
    }

    private bool invalidated = true;

    [GtkChild]
    private Widgets.Avatar avatar;
    [GtkChild]
    private Spinner spinner;

    [GtkChild]
    private ListBox account_list;

    [GtkChild]
    private ModelButton item_accounts;
    [GtkChild]
    private ModelButton item_prefs;
    [GtkChild]
    private ModelButton item_refresh;
    [GtkChild]
    private ModelButton item_search;
    [GtkChild]
    private ModelButton item_favs;
    [GtkChild]
    private ModelButton item_direct;
    [GtkChild]
    private ModelButton item_watchlist;

    construct {
        connect_account ();

        item_refresh.clicked.connect (() => app.refresh ());
        Desktop.set_hotkey_tooltip (item_refresh, null, app.ACCEL_REFRESH);

        item_favs.clicked.connect (() => window.open_view (new Views.Favorites ()));
        item_direct.clicked.connect (() => window.open_view (new Views.Direct ()));
        item_search.clicked.connect (() => window.open_view (new Views.Search ()));
        //item_watchlist.clicked.connect (() => Dialogs.WatchlistEditor.open ());
        item_prefs.clicked.connect (() => Dialogs.Preferences.open ());

        // network.started.connect (() => spinner.show ());
        // network.finished.connect (() => spinner.hide ());

        on_account_changed (null);

        notify["active"].connect (() => {
            if (active && invalidated)
                rebuild ();
        });

        account_list.row_activated.connect (on_selection_changed) ;
    }

    protected void on_selection_changed (ListBoxRow r) {
        var i = r.get_index ();
        if (i >= accounts.saved.size) {
            active = false;
            window.open_view (new Views.NewAccount (true));
            return;
        }

        var account = accounts.saved.@get (i);
        if (accounts.active == account)
            return;

        accounts.switch_account (i);
    }

    public virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
    	invalidated = true;
    	if (active)
    	    rebuild ();
    }

    public virtual void on_account_changed (InstanceAccount? account) {
    	if (account == null) {
    	    avatar.url = null;
    	    item_accounts.text = "<b>" + _("No active account") + "</b>";
    	}
    	else {
    	    avatar.url = account.avatar;
    	    item_accounts.text = @"<b>$(account.display_name)</b>\n$(account.handle)   ";
    	}
    	item_accounts.use_markup = true;
    }

    private void rebuild () {
        account_list.@foreach (w => account_list.remove (w));
        accounts.saved.@foreach (acc => {
            var item = new Item (acc, this);
            var row = new ListBoxRow ();
            row.add (item);
            row.show ();

            account_list.insert (row, -1);
            if (accounts.active == acc)
                row.activate ();

            return true;
        });
        var new_row = new ListBoxRow ();
        new_row.add (new Item.add_new ());
        new_row.selectable = false;
        new_row.show ();
        account_list.insert (new_row, -1);

        invalidated = false;
    }

}
