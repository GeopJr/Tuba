using Gtk;
using Granite;

public class Tootle.AccountView : Tootle.HomeView {
    
    Account account;
    
    Gtk.Grid header;
    Gtk.Grid header_image;
    Gtk.Box header_info;
    Granite.Widgets.Avatar avatar;
    Gtk.Label display_name;
    Gtk.Label username;
    Tootle.RichLabel note;
    Gtk.Grid counters;
    
    public override void pre_construct () {
        header = new Gtk.Grid ();
    
        header_info = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        header_info.margin = 16;
    
        avatar = new Granite.Widgets.Avatar.with_default_icon (128);
        avatar.hexpand = true;
        avatar.margin = 16;
        header_info.pack_start(avatar, false, false, 0);
        
        display_name = new RichLabel ("");
        display_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_info.pack_start(display_name, false, false, 0);
        
        username = new Gtk.Label ("");
        username.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        header_info.pack_start(username, false, false, 0);
        
        note = new RichLabel ("");
		note.set_line_wrap (true);
		note.selectable = true;
		note.margin_top = 16;
        note.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        note.justify = Gtk.Justification.CENTER;
        header_info.pack_start(note, false, false, 0);
        header_info.show_all ();
        header.attach (header_info, 0, 0, 1, 1);
        
        counters = new Gtk.Grid ();
        counters.column_homogeneous = true;
        counters.get_style_context ().add_class ("header-counters");
        header.attach (counters, 0, 1, 1, 1);
        
        header_image = new Gtk.Grid ();
        header_image.get_style_context ().add_class ("header");
        header.attach (header_image, 0, 0, 2, 2);
        
        view.pack_start (header, false, false, 0);
    }
    
    public AccountView (Account acc) {
        base ("account_"+acc.id.to_string ());
        account = acc;
        
        display_name.label = "<b>%s</b>".printf (account.display_name);
        username.label = "@" + account.acct;
        note.label = Utils.escape_html (account.note);
        Tootle.cache.load_avatar (account.avatar, avatar, 128);
        
        add_counter (_("TOOTS"), 1, account.statuses_count);
        add_counter (_("FOLLOWS"), 2, account.following_count);
        add_counter (_("FOLLOWERS"), 3, account.followers_count);
        show_all ();
        
        var stylesheet = ".header{background-image: url(\"%s\")}".printf (account.header);
        var css_provider = Granite.Widgets.Utils.get_css_provider (stylesheet);
        header_image.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        request ();
    }
    
    private void add_counter (string name, int i, int64 val) {
        var label_name = new Gtk.Label (name);
        label_name.margin_top = 8;
        label_name.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        var label_val = new Gtk.Label (val.to_string ());
        label_val.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        label_val.margin_bottom = 8;
        counters.attach (label_name, i, 1, 1, 1);
        counters.attach (label_val, i, 2, 1, 1);
    }
    
    public override bool is_status_owned (Status status){
        return status.account.id == account.id;
    }
    
    public override string get_url (){
        var url = "%s/api/v1/accounts/%lld/statuses".printf (Tootle.settings.instance_url, account.id);
        url += "?limit=25";
        
        if (max_id > 0)
            url += "&max_id=" + max_id.to_string ();
            
        return url;
    }
    
    public static void open_from_id (int64 id){
        var url = "%s/api/v1/accounts/%lld".printf (Tootle.settings.instance_url, id);
        var msg = new Soup.Message("GET", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                var acc = Account.parse (root);
                Tootle.window.open_secondary_view (new AccountView (acc));
            }
            catch (GLib.Error e) {
                warning ("Can't update feed");
                warning (e.message);
            }
        });
    }
    
    public static void open_from_name (string name){
        var url = "%s/api/v1/accounts/search?limit=1&q=%s".printf (Tootle.settings.instance_url, name);
        var msg = new Soup.Message("GET", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var node = Tootle.network.parse_array (mess).get_element (0);
                var object = node.get_object ();
                if (object != null){
                    var acc = Account.parse(object);
                    Tootle.window.open_secondary_view (new AccountView (acc));
                }
                else
                    warning ("No results found for account: "+name); //TODO: toast notifications
            }
            catch (GLib.Error e) {
                warning ("Can't update feed");
                warning (e.message);
            }
        });
    }
    
}
