using Gdk;

public class Tootle.Widgets.Account : Widgets.Status {

    public Account (API.Account account) {
        var status = new API.Status (-1);
        status.account = account;
        //status.url = account.url;
        //status.content = "<a href=\"%s\">@%s</a>".printf (account.url, account.acct);
        //status.created_at = account.created_at;

        base (status);

        //counters.visible = false;
        //title_acct.visible = false;
        //content_label.margin_bottom = 12;
    }

    protected override bool on_clicked (EventButton ev) {
        if (ev.button == 1)
            return on_avatar_clicked (ev);
        return false;
    }

    public override bool open_menu (uint button, uint32 time) {
        var menu = new Gtk.Menu ();

        var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
        item_open_link.activate.connect (() => Desktop.open_uri (status.url));
        var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
        item_copy_link.activate.connect (() => Desktop.copy (status.url));
        menu.add (item_open_link);
        menu.add (item_copy_link);

        menu.show_all ();
        menu.popup_at_pointer ();
        return true;
    }

}
