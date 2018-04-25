using Gtk;
using Granite;

public class Tootle.AccountView : Tootle.AbstractView {
    
    Account account;
    
    Gtk.Grid header;
    Gtk.Grid header_image;
    Granite.Widgets.Avatar avatar;
    Gtk.Label display_name;
    Gtk.Label username;
    Gtk.Label note;
    Gtk.Grid counters;
    
    construct {
        header = new Gtk.Grid ();
    
        avatar = new Granite.Widgets.Avatar.with_default_icon (128);
        avatar.hexpand = true;
        avatar.margin_top = 16;
        avatar.margin_bottom = 16;
        header.attach (avatar, 0, 1, 1, 1);
        
        display_name = new Gtk.Label ("");
        display_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header.attach (display_name, 0, 2, 1, 1);
        
        username = new Gtk.Label ("");
        username.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        header.attach (username, 0, 3, 1, 1);
        
        note = new Gtk.Label ("");
        note.set_use_markup (true);
		note.set_line_wrap (true);
        note.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        note.justify = Gtk.Justification.CENTER;
        note.margin_start = 16;
        note.margin_end = 16;
        header.attach (note, 0, 4, 1, 1);
        
        counters = new Gtk.Grid ();
        counters.margin_top = 16;
        counters.column_homogeneous = true;
        header.attach (counters, 0, 5, 1, 1);
        
        header_image = new Gtk.Grid ();
        header_image.get_style_context ().add_class ("header");
        header.attach (header_image, 0, 1, 1, 5);
        
        view.pack_start (header, false, false, 0);
    }
    
    public AccountView (Account acc){
        base (false);
        account = acc;
        
        display_name.label = account.display_name;
        username.label = "@" + account.acct;
        note.label = Utils.escape_html (account.note);
        CacheManager.instance.load_avatar (account.avatar, avatar, 128);
        
        add_counter (_("Toots"), 1, account.statuses_count);
        add_counter (_("Follows"), 2, account.following_count);
        add_counter (_("Followers"), 3, account.followers_count);
        show_all ();
        
        var stylesheet = ".header{background-image: url(\"%s\")}".printf (account.header);
        var css_provider = Granite.Widgets.Utils.get_css_provider (stylesheet);
        header_image.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
    }
    
    private void add_counter (string name, int i, int64 val){
        var label_name = new Gtk.Label (name);
        var label_val = new Gtk.Label (val.to_string ());
        counters.attach (label_name, i, 1, 1, 1);
        counters.attach (label_val, i, 2, 1, 1);
    }
    
}
