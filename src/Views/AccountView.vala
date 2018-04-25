using Gtk;
using Granite;

public class Tootle.AccountView : Tootle.AbstractView {
    
    Account account;
    
    Gtk.Box header;
    Granite.Widgets.Avatar avatar;
    Gtk.Label display_name;
    Gtk.Label username;
    Gtk.Label note;
    
    construct {
        header = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        header.margin = 16;
    
        avatar = new Granite.Widgets.Avatar.with_default_icon (128);
        header.pack_start (avatar, false, false, 0);
        
        display_name = new Gtk.Label ("");
        display_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header.pack_start (display_name, false, false, 0);
        username = new Gtk.Label ("");
        username.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        header.pack_start (username, false, false, 0);
        note = new Gtk.Label ("");
        note.set_use_markup (true);
		note.set_line_wrap (true);
        note.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        note.justify = Gtk.Justification.CENTER;
        header.pack_start (note, false, false, 0);
        
        view.pack_start (header, false, false, 0);
    }
    
    public AccountView (Account acc){
        base (false);
        account = acc;
        
        display_name.label = account.display_name;
        username.label = "@" + account.acct;
        note.label = Utils.escape_html (account.note);
        CacheManager.instance.load_avatar (account.avatar, avatar, 128);
    }
    
}
