using Gtk;
using Granite;

public class Tootle.AccountView : Tootle.HomeView {
    
    Account account;
    Relationship? relationship;
    
    Gtk.Grid header;
    Gtk.Grid header_image;
    Gtk.Box header_info;
    Granite.Widgets.Avatar avatar;
    Gtk.Label display_name;
    Gtk.Label username;
    Tootle.RichLabel note;
    Gtk.Grid counters;
    Gtk.Box actions;
    Gtk.Button button_follow;
    Gtk.Button button_more;
    
    public override void pre_construct () {
        header = new Gtk.Grid ();
        header_info = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        header_info.margin = 16;
        actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        actions.hexpand = false;
        actions.halign = Gtk.Align.END;
        actions.vexpand = false;
        actions.valign = Gtk.Align.START;
        actions.margin = 16;
    
        avatar = new Granite.Widgets.Avatar.with_default_icon (128);
        avatar.hexpand = true;
        avatar.margin_bottom = 8;
        header_info.pack_start(avatar, false, false, 0);
        
        display_name = new RichLabel ("");
        display_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_info.pack_start(display_name, false, false, 0);
        
        username = new Gtk.Label ("");
        header_info.pack_start(username, false, false, 0);
        
        note = new RichLabel ("");
        note.set_line_wrap (true);
        note.selectable = true;
        note.margin_top = 16;
        note.can_focus = false;
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
        
        button_follow = add_counter ("contact-new-symbolic");
        button_follow.hide ();
        button_more = add_counter ("view-more-symbolic");
        button_more.tooltip_text = _("More Actions");
        actions.pack_end(button_more, false, false, 0);
        actions.pack_end(button_follow, false, false, 0);
        header.attach (actions, 0, 0, 2, 2);
        
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
        
        button_follow.visible = !is_owned ();
        button_follow.clicked.connect (() => toggle_follow ());
        
        request_relationship ();
        request ();
    }
    
    public void rebind (){
        if (relationship != null && !is_owned ()) {
            button_follow.show ();
            if (relationship.following) {
                button_follow.tooltip_text = _("Unfollow");
                (button_follow.get_image () as Gtk.Image).icon_name = "close-symbolic";
            }
            else{
                button_follow.tooltip_text = _("Follow");
                (button_follow.get_image () as Gtk.Image).icon_name = "contact-new-symbolic";
            }
        }
    }
    
    private Gtk.Button add_counter (string name, int? i = null, int64? val = null) {
        Gtk.Button btn;
        if (val != null){
            btn = new Gtk.Button ();
            var label = new Gtk.Label (name + "\n" + val.to_string ());
            label.justify = Gtk.Justification.CENTER;
            btn.add (label);
        }
        else
            btn = new Gtk.Button.from_icon_name (name, Gtk.IconSize.LARGE_TOOLBAR);
            
        btn.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        btn.set_focus_on_click (false);
        btn.can_default = false;
        btn.can_focus = false;
        
        if (i != null)
            counters.attach (btn, i, 1, 1, 1);
        return btn;
    }
    
    public bool is_owned (){
        return account.id == Tootle.accounts.current.id;
    }
    
    public override bool is_status_owned (Status status){
        return status.get_formal ().account.id == account.id;
    }
    
    public override string get_url (){
        var url = "%s/api/v1/accounts/%lld/statuses".printf (Tootle.settings.instance_url, account.id);
        url += "?limit=25";
        
        if (max_id > 0)
            url += "&max_id=" + max_id.to_string ();
            
        return url;
    }
    
    public void request_relationship (){
        var url = "%s/api/v1/accounts/relationships?id=%lld".printf (Tootle.settings.instance_url, account.id);
        var msg = new Soup.Message("GET", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse_array (mess).get_object_element (0);
                relationship = Relationship.parse (root);
                rebind ();
            }
            catch (GLib.Error e) {
                warning ("Can't get relationship:");
                warning (e.message);
            }
        });
    }
    
    public void toggle_follow (){
        var action = relationship.following ? "unfollow" : "follow"; 
        var url = "%s/api/v1/accounts/%lld/%s".printf (Tootle.settings.instance_url, account.id, action);
        var msg = new Soup.Message("POST", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                relationship = Relationship.parse (root);
                rebind ();
            }
            catch (GLib.Error e) {
                Tootle.app.error (_("Error"), e.message);
                warning (e.message);
            }
        });
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
