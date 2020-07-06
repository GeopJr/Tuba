using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button.ui")]
public class Tootle.Widgets.AccountsButton : Gtk.MenuButton, IAccountListener {

    [GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/accounts_button_item.ui")]
    class Item : Grid {
        [GtkChild]
        Widgets.Avatar avatar;
        [GtkChild]
        Label title;
        [GtkChild]
        Label handle;
        [GtkChild]
        Button profile;
        [GtkChild]
        Button forget;

        public Item (InstanceAccount acc, AccountsButton _self) {
            avatar.url = acc.avatar;
            title.label = acc.display_name;
            handle.label = acc.handle;

            profile.clicked.connect (() => {
                Views.Profile.open_from_id (acc.id);
                _self.active = false;
            });

            forget.clicked.connect (() => {
                _self.active = false;
                accounts.remove (acc);
            });
        }

        public Item.add_new () {
            title.label = _("New Account");
            handle.label = _("Click to add");
            profile.destroy ();
            forget.destroy ();
        }
    }

    bool invalidated = true;

    [GtkChild]
    Widgets.Avatar avatar;

    [GtkChild]
    ListBox account_list;

    [GtkChild]
    ModelButton item_accounts;
    [GtkChild]
    ModelButton item_prefs;
    [GtkChild]
    ModelButton item_refresh;
    [GtkChild]
    ModelButton item_search;
    [GtkChild]
    Button item_favs;
    [GtkChild]
    Button item_conversations;
    [GtkChild]
    Button item_bookmarks;

    construct {
        connect_account ();

        item_refresh.clicked.connect (() => {
            app.refresh ();
        });
        Desktop.set_hotkey_tooltip (item_refresh, null, app.ACCEL_REFRESH);

        item_favs.clicked.connect (() => {
            window.open_view (new Views.Favorites ());
            popover.popdown ();
        });
        item_conversations.clicked.connect (() => {
            window.open_view (new Views.Conversations ());
            popover.popdown ();
        });
        item_bookmarks.clicked.connect (() => {
            window.open_view (new Views.Bookmarks ());
            popover.popdown ();
        });
        item_search.clicked.connect (() => {
            window.open_view (new Views.Search ());
            popover.popdown ();
        });
        item_prefs.clicked.connect (() => {
            Dialogs.Preferences.open ();
            popover.popdown ();
        });

        on_account_changed (null);

        notify["active"].connect (() => {
            if (active && invalidated)
                rebuild ();
        });

        account_list.row_activated.connect (on_selection_changed);
    }

    protected void on_selection_changed (ListBoxRow r) {
        var i = r.get_index ();
        if (i >= accounts.saved.size) {
            active = false;
            window.open_view (new Views.NewAccount (true));
            popover.popdown ();
            return;
        }

        var account = accounts.saved.@get (i);
        if (accounts.active == account)
            return;

        accounts.switch_account (i);
        popover.popdown ();
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

    void rebuild () {
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
