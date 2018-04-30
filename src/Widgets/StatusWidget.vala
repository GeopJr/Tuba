using Gtk;
using Granite;

public class Tootle.StatusWidget : Gtk.EventBox {
    
    public Status status;
    
    public int avatar_size;
    public Granite.Widgets.Avatar avatar;
    public Gtk.Label user;
    public Gtk.Revealer revealer;
    public Tootle.RichLabel content;
    public Gtk.Separator? separator;
    public Gtk.Label? spoiler_content;
    Gtk.Grid grid;
    Gtk.Box counters;
    Gtk.Label reblogs;
    Gtk.Label favorites;
    Gtk.ToggleButton reblog;
    Gtk.ToggleButton favorite;
    Gtk.ToggleButton reply;
    Gtk.Button? spoiler_button;

    construct {
        grid = new Gtk.Grid ();
        grid.margin = 6;
        
        avatar_size = 32;
        avatar = new Granite.Widgets.Avatar.with_default_icon (avatar_size);
        avatar.valign = Gtk.Align.START;
        avatar.margin_end = 6;
        user = new Gtk.Label ("");
        user.hexpand = true;
        user.halign = Gtk.Align.START;
        user.use_markup = true;
        
        content = new RichLabel ("");
        content.halign = Gtk.Align.START;
        content.single_line_mode = false;
        content.set_line_wrap (true);
        content.wrap_mode = Pango.WrapMode.WORD_CHAR;
        content.justify = Gtk.Justification.LEFT;
        content.margin_end = 6;
        content.xalign = 0;
        revealer = new Revealer ();
        revealer.reveal_child = true;
        revealer.add (content);
        
        reblogs = new Gtk.Label ("0");
        favorites = new Gtk.Label ("0");
        
        reblog = get_action_button ("go-up-symbolic");
        reblog.tooltip_text = _("Boost");
        reblog.toggled.connect (() => {
            if (reblog.sensitive)
                toggle_reblog ();
        });
        favorite = get_action_button ("help-about-symbolic");
        favorite.tooltip_text = _("Favorite");
        favorite.toggled.connect (() => {
            if (favorite.sensitive)
                toggle_fav ();
        });
        reply = get_action_button ("edit-undo-symbolic");
        reply.tooltip_text = _("Reply");
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
        
        grid.attach (avatar, 1, 1, 1, 4);
        grid.attach (user, 2, 2, 1, 1);
        grid.attach (revealer, 2, 4, 1, 1);
        grid.attach (counters, 2, 5, 1, 1);
        add (grid);
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
            var label = new RichLabel (label_text);
            label.halign = Gtk.Align.START;
            label.margin_bottom = 8;
            label.show ();
            
            grid.attach (image, 1, 0, 1, 1);
            grid.attach (label, 2, 0, 2, 1);
        }
        
        if (status.spoiler_text != null){
            revealer.reveal_child = false;
            spoiler_button = new Button.with_label (_("Toggle content"));
            spoiler_content = new RichLabel (status.spoiler_text);
            
            var spoiler_box = new Box (Gtk.Orientation.HORIZONTAL, 6);
            spoiler_box.add (spoiler_content);
            spoiler_box.add (spoiler_button);
            spoiler_box.show_all ();
            
            spoiler_button.clicked.connect (() => revealer.set_reveal_child (!revealer.child_revealed));
            grid.attach (spoiler_box, 2, 3, 1, 1);
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
        user.label = "<b>%s</b>".printf (status.get_formal ().account.display_name);
        content.label = status.content;
        content.mentions = status.mentions;
        
        reblogs.label = status.reblogs_count.to_string ();
        favorites.label = status.favourites_count.to_string ();
        
        reblog.sensitive = false;
        reblog.active = status.reblogged;
        reblog.sensitive = true;
        favorite.sensitive = false;
        favorite.active = status.favorited;
        favorite.sensitive = true;
        
        Tootle.cache.load_avatar (status.get_formal ().account.avatar, this.avatar, this.avatar_size);
    }
    
    public bool on_avatar_clicked (){
        var view = new AccountView (status.get_formal ().account);
        Tootle.window.open_secondary_view (view);
        return true;
    }
    
    public bool open (){
        var view = new StatusView (status.get_formal ());
        Tootle.window.open_secondary_view (view);
        return false;
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
        var action = state ? "reblog" : "unreblog";
        var msg = new Soup.Message("POST", Tootle.settings.instance_url + "/api/v1/statuses/" + status.id.to_string () + "/" + action);
        msg.finished.connect (() => {
            status.reblogged = state;
            if (state)
                status.reblogs_count += 1;
            else
                status.reblogs_count -= 1;
            rebind ();
        });
        Tootle.network.queue (msg, (sess, mess) => {
            if(state)
                Tootle.app.toast (_("Boosted!"));
            else
                Tootle.app.toast (_("Removed boost"));
        });
    }
    
    public void toggle_fav (){
        var state = favorite.get_active ();
        var action = state ? "favourite" : "unfavourite";
        var msg = new Soup.Message ("POST", Tootle.settings.instance_url + "/api/v1/statuses/" + status.id.to_string () + "/" + action);
        msg.finished.connect (() => {
            status.favorited = state;
            if (state)
                status.favourites_count += 1;
            else
                status.favourites_count -= 1;
            rebind ();
        });
        Tootle.network.queue (msg, (sess, mess) => {
            if(state)
                Tootle.app.toast (_("Favorited!"));
            else
                Tootle.app.toast (_("Removed favorite"));
        });
    }

}
