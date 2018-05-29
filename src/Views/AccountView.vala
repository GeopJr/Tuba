using Gtk;
using Granite;

public class Tootle.AccountView : TimelineView {
    
    Account account;
    
    Gtk.Grid header;
    Gtk.Grid header_image;
    Gtk.Box header_info;
    Granite.Widgets.Avatar avatar;
    Gtk.Label display_name;
    Gtk.Label username;
    Gtk.Label relationship;
    Tootle.RichLabel note;
    Gtk.Grid counters;
    Gtk.Box actions;
    Gtk.Button button_follow;
    
    Gtk.Menu menu;
    Gtk.MenuItem menu_edit;
    Gtk.MenuItem menu_mention;
    Gtk.MenuItem menu_mute;
    Gtk.MenuItem menu_block;
    Gtk.MenuItem menu_report;
    Gtk.MenuButton button_menu;
    
    public override void pre_construct () {
        header = new Gtk.Grid ();
        header_info = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        header_info.margin = 12;
        actions = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        actions.hexpand = false;
        actions.halign = Gtk.Align.END;
        actions.vexpand = false;
        actions.valign = Gtk.Align.START;
        actions.margin = 12;
    
        relationship = new Gtk.Label ("");
        relationship.get_style_context ().add_class ("relationship");
        relationship.halign = Gtk.Align.START;
        relationship.valign = Gtk.Align.START;
        relationship.margin = 12;
        header.attach (relationship, 0, 0, 1, 1);
    
        avatar = new Granite.Widgets.Avatar.with_default_icon (128);
        avatar.hexpand = true;
        avatar.margin_bottom = 6;
        header_info.pack_start(avatar, false, false, 0);
        
        display_name = new RichLabel ("");
        display_name.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        header_info.pack_start(display_name, false, false, 0);
        
        username = new Gtk.Label ("");
        header_info.pack_start(username, false, false, 0);
        
        note = new RichLabel ("");
        note.set_line_wrap (true);
        note.selectable = true;
        note.margin_top = 12;
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
        
        menu = new Gtk.Menu ();
        menu_edit = new Gtk.MenuItem.with_label (_("Edit Profile"));
        menu_mention = new Gtk.MenuItem.with_label (_("Mention"));
        menu_report = new Gtk.MenuItem.with_label (_("Report"));
        menu_mute = new Gtk.MenuItem.with_label (_("Mute"));
        menu_block = new Gtk.MenuItem.with_label (_("Block"));
        menu.add (menu_mention);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (menu_mute);
        menu.add (menu_block);
        //menu.add (menu_report); //TODO: Report users
        menu.add (menu_edit); //TODO: Edit profile
        menu.show_all ();
        
        button_follow = add_counter ("contact-new-symbolic");
        button_menu = new Gtk.MenuButton ();
        button_menu.image = new Gtk.Image.from_icon_name ("view-more-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        button_menu.tooltip_text = _("More Actions");
        button_menu.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button_menu.set_focus_on_click (false);
        button_menu.can_default = false;
        button_menu.can_focus = false;
        button_menu.popup = menu;
        actions.pack_end(button_menu, false, false, 0);
        actions.pack_end(button_follow, false, false, 0);
        button_menu.hide ();
        button_follow.hide ();
        header.attach (actions, 0, 0, 2, 2);
        
        view.pack_start (header, false, false, 0);
    }
    
    public AccountView (Account acc) {
        base ("");
        account = acc;
        account.updated.connect(rebind);
        
        add_counter (_("TOOTS"), 1, account.statuses_count);
        add_counter (_("FOLLOWS"), 2, account.following_count).clicked.connect (() => {
            var view = new FollowingView (ref account);
            Tootle.window.open_view (view);
        });
        add_counter (_("FOLLOWERS"), 3, account.followers_count).clicked.connect (() => {
            var view = new FollowersView (ref account);
            Tootle.window.open_view (view);
        });
        
        show_all ();
        
        var stylesheet = ".header{background-image: url(\"%s\")}".printf (account.header);
        var css_provider = Granite.Widgets.Utils.get_css_provider (stylesheet);
        header_image.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        
        menu_mention.activate.connect (() => PostDialog.open ("@%s ".printf (account.acct)));
        menu_mute.activate.connect (() => account.set_muted (!account.rs.muting));
        menu_block.activate.connect (() => account.set_blocked (!account.rs.blocking));
        button_follow.clicked.connect (() => account.set_following (!account.rs.following));
        
        rebind ();
        account.get_relationship ();
        request ();
    }
    
    public void rebind (){
        display_name.label = "<b>%s</b>".printf (Utils.escape_entities(account.display_name));
        username.label = "@" + account.acct;
        note.label = Utils.simplify_html (account.note);
        button_follow.visible = !account.is_self ();
        Tootle.image_cache.load_avatar (account.avatar, avatar, 128);
        
        menu_edit.visible = account.is_self ();
    
        if (account.rs != null && !account.is_self ()) {
            button_follow.show ();
            if (account.rs.following) {
                button_follow.tooltip_text = _("Unfollow");
                (button_follow.get_image () as Gtk.Image).icon_name = "close-symbolic";
            }
            else{
                button_follow.tooltip_text = _("Follow");
                (button_follow.get_image () as Gtk.Image).icon_name = "contact-new-symbolic";
            }
        }
        
        if (account.rs != null){
            button_menu.show ();
            menu_block.label = account.rs.blocking ? _("Unblock") : _("Block");
            menu_mute.label = account.rs.muting ? _("Unmute") : _("Mute");
            menu_report.visible = menu_mute.visible = menu_block.visible = !account.is_self ();
            
            var rs_label = get_relationship_label ();
            if (rs_label != null) {
                relationship.label = rs_label;
                relationship.show ();
            }
            else
                relationship.hide ();
        }
        else
            relationship.hide ();
    }
    
    public override bool is_status_owned (ref Status status) {
        return status.get_formal().account.id == account.id;
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
    
    public override bool is_empty () {
        return view.get_children ().length () <= 2;
    }
    
    public override string get_url () {
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/accounts/%lld/statuses?limit=%i".printf (Tootle.accounts.formal.instance, account.id, this.limit);
        return url;
    }
    
    public override void request () {
        if(account != null)
            base.request ();
    }
    
    private string? get_relationship_label () {
        if (account.rs.requested)
            return _("Sent follow request");
        else if (account.rs.blocking)
            return _("Blocked");
        else if (account.rs.followed_by)
            return _("Follows you");
        else if (account.rs.domain_blocking)
            return _("Blocking this instance");
        else
            return null;
    }
    
    public static void open_from_id (int64 id){
        var url = "%s/api/v1/accounts/%lld".printf (Tootle.accounts.formal.instance, id);
        var msg = new Soup.Message("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                var acc = Account.parse (root);
                Tootle.window.open_view (new AccountView (acc));
            }
            catch (GLib.Error e) {
                warning ("Can't update feed");
                warning (e.message);
            }
        });
    }
    
    public static void open_from_name (string name){
        var url = "%s/api/v1/accounts/search?limit=1&q=%s".printf (Tootle.accounts.formal.instance, name);
        var msg = new Soup.Message("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var node = Tootle.network.parse_array (mess).get_element (0);
                var object = node.get_object ();
                if (object != null){
                    var acc = Account.parse(object);
                    Tootle.window.open_view (new AccountView (acc));
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
