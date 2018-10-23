public class Tootle.AccountWidget : StatusWidget {

    public AccountWidget (Account account) {
        var status = new Status (-1);
        status.account = account;
        status.url = account.url;
        status.content = "<a href=\"%s\">@%s</a>".printf (account.url, account.acct);
        status.created_at = account.created_at;
        
        base (status);
        
        counters.visible = false;
        title_acct.visible = false;
        content_label.margin_bottom = 12;
        button_press_event.connect(() => {
            open_account ();
            return true;
        });
    }
    
    public override bool open_menu (uint button, uint32 time) {
        var menu = new Gtk.Menu ();
        menu.selection_done.connect (() => {
            menu.detach ();
            menu.destroy ();
        });
        
        var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
        item_open_link.activate.connect (() => Desktop.open_uri (status.url));
        var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
        item_copy_link.activate.connect (() => Desktop.copy (status.url));
        menu.add (item_open_link);
        menu.add (item_copy_link);
        
        menu.show_all ();
        menu.attach_widget = this;
        menu.popup (null, null, null, button, time);
        return true;
    }

}
