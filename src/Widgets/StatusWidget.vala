using Gtk;
using Granite;

public class Tootle.StatusWidget : Gtk.Grid {
    
    public Status status;
    
    public int avatar_size;
    public Granite.Widgets.Avatar avatar;
    public Gtk.Label user;
    public Gtk.Revealer revealer;
    public Gtk.Label content;
    public Gtk.Separator? separator;
    public Gtk.Label? spoiler_content;
    Gtk.Box counters;
    Gtk.Label reblogs;
    Gtk.Label favorites;
    Gtk.ToggleButton reblog;
    Gtk.ToggleButton favorite;
    Gtk.ToggleButton reply;
    Gtk.Button? spoiler_button;

    construct {
        margin = 6;
        
        avatar_size = 32;
        avatar = new Granite.Widgets.Avatar.with_default_icon (avatar_size);
        avatar.valign = Gtk.Align.START;
        avatar.margin_end = 6;
        user = new Gtk.Label (_("Anonymous"));
        user.hexpand = true;
        user.halign = Gtk.Align.START;
        user.use_markup = true;
        
        content = new Gtk.Label (_("Error parsing text :c"));
        content.halign = Gtk.Align.START;
        content.use_markup = true;
        content.single_line_mode = false;
        content.set_line_wrap (true);
        content.justify = Gtk.Justification.LEFT;
        content.margin_end = 6;
        content.xalign = 0;
        revealer = new Revealer ();
        revealer.reveal_child = true;
        revealer.add (content);
        
        reblogs = new Gtk.Label ("0");
        favorites = new Gtk.Label ("0");
        
        reblog = get_action_button ("go-up-symbolic");
        reblog.toggled.connect (() => {
            if (reblog.sensitive)
                toggle_reblog ();
        });
        favorite = get_action_button ("help-about-symbolic");
        favorite.toggled.connect (() => {
            if (favorite.sensitive)
                toggle_fav ();
        });
        reply = get_action_button ("edit-undo-symbolic");
        reply.toggled.connect (() => {
            reply.set_active (false);
            PostDialog.open_reply (Tootle.window, this.status);
        });
        
        counters = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6); //TODO: currently useless
        counters.margin_top = 6;
        counters.add (reblog);
        counters.add (reblogs);
        counters.add (favorite);
        counters.add (favorites);
        counters.add (reply);
        counters.show_all ();
        
        attach (avatar, 1, 1, 1, 4);
        attach (user, 2, 2, 1, 1);
        attach (revealer, 2, 4, 1, 1);
        attach (counters, 2, 5, 1, 1);
        show_all (); //TODO: display conversations
    }

    public StatusWidget (Status status) {
        this.status = status;
        get_style_context ().add_class ("status");
        
        if (status.reblog != null){
            var image = new Gtk.Image.from_icon_name("go-up-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
            image.halign = Gtk.Align.END;
            image.margin_end = 8;
            image.show ();
            
            var label_text = _("<a href=\"%s\"><b>%s</b></a> boosted").printf (status.account.url, status.account.display_name);
            var label = new Gtk.Label (label_text);
            label.halign = Gtk.Align.START;
            label.use_markup = true;
            label.margin_bottom = 8;
            label.show ();
            
            attach (image, 1, 0, 1, 1);
            attach (label, 2, 0, 2, 1);
        }
        
        if (status.spoiler_text != null){
            revealer.reveal_child = false;
            spoiler_button = new Button.with_label (_("Show content"));
            spoiler_content = new Label (status.spoiler_text);
            
            var spoiler_box = new Box (Gtk.Orientation.HORIZONTAL, 6);
            spoiler_box.add (spoiler_content);
            spoiler_box.add (spoiler_button);
            spoiler_box.show_all ();
            
            spoiler_button.clicked.connect (() => revealer.set_reveal_child (!revealer.child_revealed));
            attach (spoiler_box, 2, 3, 1, 1);
        }
        
        destroy.connect (() => {
            if(separator != null)
                separator.destroy ();
        });
    }
    
    public void highlight (){
        content.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        if (spoiler_content != null)
            spoiler_content.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        avatar_size = 48;
        avatar.show_default (avatar_size);
    }
    
    public void rebind (Status status = this.status){
        var user_label = status.reblog != null ? status.reblog.account.display_name : status.account.display_name;
        user.label = "<b>%s</b>".printf (user_label);
        content.label = status.content;
        
        reblogs.label = status.reblogs_count.to_string ();
        favorites.label = status.favourites_count.to_string ();
        
        reblog.active = status.reblogged;
        reblog.sensitive = true;
        favorite.active = status.favorited;
        favorite.sensitive = true;
        
        var avatar_url = status.reblog != null ? status.reblog.account.avatar : status.account.avatar;
        CacheManager.instance.load_avatar (avatar_url, this.avatar, this.avatar_size);
    }
    
    private Gtk.ToggleButton get_action_button (string icon_path){
        var icon = new Gtk.Image.from_icon_name (icon_path, Gtk.IconSize.SMALL_TOOLBAR);
        var button = new Gtk.ToggleButton ();
        button.can_default = false;
        button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        button.add (icon);
        return button;
    }
    
    public void toggle_reblog (){
        var state = reblog.get_active ();
        var action = "reblog";
        if (!state)
            action = "unreblog";

        var msg = new Soup.Message("POST", Settings.instance.instance_url + "/api/v1/statuses/" + status.id.to_string () + "/" + action);
        msg.finished.connect (() => {
            status.reblogged = state;
            reblog.sensitive = false;
            favorite.sensitive = false;
            if (state)
                status.reblogs_count += 1;
            else
                status.reblogs_count -= 1;
            rebind ();
        });
        NetManager.instance.queue (msg, (sess, mess) => {
            //NetManager.parse (msg);
        });
    }
    
    public void toggle_fav (){
        var state = favorite.get_active ();
        var action = "favourite";
        if (!state)
            action = "unfavourite";

        var msg = new Soup.Message ("POST", Settings.instance.instance_url + "/api/v1/statuses/" + status.id.to_string () + "/" + action);
        msg.finished.connect (() => {
            status.favorited = state;
            reblog.sensitive = false;
            favorite.sensitive = false;
            if (state)
                status.favourites_count += 1;
            else
                status.favourites_count -= 1;
            rebind ();
        });
        NetManager.instance.queue (msg, (sess, mess) => {
            //NetManager.parse (msg);
        });
    }

}
