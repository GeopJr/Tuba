using Gtk;
using Granite;

public class Tootle.StatusWidget : Gtk.EventBox {
    
    public Status status;
    public int64? date_utc;
    
    public int avatar_size;
    public Gtk.Separator? separator;
    public Granite.Widgets.Avatar avatar;
    public Gtk.Label title_user;
    public Gtk.Label title_date;
    public Gtk.Label title_acct;
    public Gtk.Revealer revealer;
    public Tootle.RichLabel content_label;
    public Tootle.RichLabel? content_spoiler;
    Gtk.Button? spoiler_button;
    Gtk.Box title_box;
    AttachmentBox attachments;
    Gtk.Grid grid;
    Gtk.Box counters;
    Gtk.Label reblogs;
    Gtk.Label favorites;
    ImageToggleButton reblog;
    ImageToggleButton favorite;
    ImageToggleButton reply;

    construct {
        grid = new Gtk.Grid ();
        
        avatar_size = 32;
        avatar = new Granite.Widgets.Avatar.with_default_icon (avatar_size);
        avatar.valign = Gtk.Align.START;
        avatar.margin_top = 6;
        avatar.margin_start = 6;
        avatar.margin_end = 6;
        
        title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        title_box.hexpand = true;
        title_box.margin_end = 12;
        title_box.margin_top = 6;
        
        title_user = new Gtk.Label ("");
        title_user.use_markup = true;
        title_box.pack_start (title_user, false, false, 0);
        
        title_acct = new Gtk.Label ("");
        title_acct.opacity = 0.5;
        title_acct.ellipsize = Pango.EllipsizeMode.END;
        title_box.pack_start (title_acct, false, false, 0);
        
        title_date = new Gtk.Label ("");
        title_date.ellipsize = Pango.EllipsizeMode.END;
        title_box.pack_end (title_date, false, false, 0);
        title_box.show_all ();
        
        content_label = new RichLabel ("");
        content_label.wrap_words ();
        
        attachments = new AttachmentBox ();
        
        reblogs = new Gtk.Label ("0");
        favorites = new Gtk.Label ("0");
        
        reblog = new ImageToggleButton ("go-up-symbolic");
        reblog.set_action ();
        reblog.tooltip_text = _("Boost");
        reblog.toggled.connect (() => {
            if (reblog.sensitive)
                status.set_reblogged (reblog.get_active ());
        });
        favorite = new ImageToggleButton ("help-about-symbolic");
        favorite.set_action ();
        favorite.tooltip_text = _("Favorite");
        favorite.toggled.connect (() => {
            if (favorite.sensitive)
                status.set_favorited (favorite.get_active ());
        });
        reply = new ImageToggleButton ("edit-undo-symbolic");
        reply.set_action ();
        reply.tooltip_text = _("Reply");
        reply.toggled.connect (() => {
            reply.set_active (false);
            PostDialog.open_reply (this.status);
        });

        var revealer_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);    
        revealer_box.margin_end = 12;
        revealer_box.add (content_label);    
        revealer_box.add (attachments);    
        revealer = new Revealer ();
        revealer.reveal_child = true;
        revealer.add (revealer_box);
        
        counters = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        counters.margin_top = 6;
        counters.margin_bottom = 6;
        counters.add (reblog);
        counters.add (reblogs);
        counters.add (favorite);
        counters.add (favorites);
        counters.add (reply);
        counters.show_all ();
        
        grid.attach (avatar, 1, 1, 1, 4);
        grid.attach (title_box, 2, 2, 1, 1);
        grid.attach (revealer, 2, 4, 1, 1);
        grid.attach (counters, 2, 5, 1, 1);
        add (grid);
        show_all ();
    }

    public StatusWidget (Status status) {
        this.status = status;
        status.updated.connect (rebind);
        get_style_context ().add_class ("status");
        
        if (status.reblog != null) {
            var image = new Gtk.Image.from_icon_name("go-up-symbolic", Gtk.IconSize.BUTTON);
            image.halign = Gtk.Align.END;
            image.margin_end = 6;
            image.margin_top = 6;
            image.show ();
            
            var label_text = _("<a href=\"%s\"><b>%s</b></a> boosted").printf (status.account.url, status.account.display_name);
            var label = new RichLabel (label_text);
            label.halign = Gtk.Align.START;
            label.margin_top = 6;
            label.show ();
            
            grid.attach (image, 1, 0, 1, 1);
            grid.attach (label, 2, 0, 2, 1);
        }
        
        if (is_spoiler ()) {
            revealer.reveal_child = false;
            var spoiler_box = new Box (Gtk.Orientation.HORIZONTAL, 6);
            spoiler_box.margin_end = 12;
            
            var spoiler_button_text = _("Toggle content");
            if (status.sensitive && status.attachments != null) {
                spoiler_button = new Button.from_icon_name ("mail-attachment-symbolic", Gtk.IconSize.BUTTON);
                spoiler_button.label = spoiler_button_text;
                spoiler_button.always_show_image = true;
                spoiler_button.hexpand = true;
                spoiler_button.halign = Gtk.Align.END;
                content_label.margin_top = 6;
            }
            else {
                spoiler_button = new Button.with_label (spoiler_button_text);
                spoiler_button.hexpand = true;
                spoiler_button.halign = Gtk.Align.END;
            }
            spoiler_button.clicked.connect (() => revealer.set_reveal_child (!revealer.child_revealed));
            
            var spoiler_text = _("[ This post contains sensitive content ]");
            if (status.spoiler_text != null)
                spoiler_text = status.spoiler_text;
            content_spoiler = new RichLabel (spoiler_text);
            content_spoiler.wrap_words ();
            
            spoiler_box.add (content_spoiler);
            spoiler_box.add (spoiler_button);
            spoiler_box.show_all ();
            grid.attach (spoiler_box, 2, 3, 1, 1);
        }
        
        if (status.attachments != null) {
            attachments.clear ();
            foreach (Attachment attachment in status.attachments)
                attachments.append (attachment);
        }
        else
            attachments.destroy ();
        
        destroy.connect (() => {
            if(separator != null)
                separator.destroy ();
        });
        
        rebind ();
    }
    
    public void highlight () {
        grid.get_style_context ().add_class ("card");
        grid.margin_bottom = 6;
    }
    
    public void rebind () {
        title_user.label = "<b>%s</b>".printf (status.get_formal ().account.display_name);
        title_acct.label = "@" + status.account.acct;
        content_label.label = status.content;
        content_label.mentions = status.mentions;
        parse_date_iso8601 (status.created_at);
        
        reblogs.label = status.reblogs_count.to_string ();
        favorites.label = status.favourites_count.to_string ();
        
        reblog.sensitive = false;
        reblog.active = status.reblogged;
        reblog.sensitive = true;
        favorite.sensitive = false;
        favorite.active = status.favorited;
        favorite.sensitive = true;
        
        if (status.visibility == StatusVisibility.DIRECT) {
            reblog.sensitive = false;
            reblog.icon.icon_name = status.visibility.get_icon ();
            reblog.tooltip_text = _("This post can't be boosted");
        }
        
        Tootle.network.load_avatar (status.get_formal ().account.avatar, this.avatar, this.avatar_size);
    }

    public bool is_spoiler () {
        return status.spoiler_text != null || status.sensitive;
    }
    
    // elementary OS has old GLib, so I have to improvise
    // Version >=2.56 provides DateTime.from_iso8601
    public void parse_date_iso8601 (string date) {
        var cmd = "date -d " + date + " +%s";
        var runner = new CmdRunner ("/bin/", cmd); //Workaround for Granite SimpleCommand pipes bug
        runner.done.connect (exit => {
            date_utc = int64.parse (runner.standard_output_str);
            var date_obj = new GLib.DateTime.from_unix_local (date_utc);
            title_date.label = Granite.DateTime.get_relative_datetime (date_obj);
        });
        runner.run ();
    }
    
    public bool on_avatar_clicked () {
        var view = new AccountView (status.get_formal ().account);
        Tootle.window.open_view (view);
        return true;
    }
    
    public bool open () {
        var view = new StatusView (status.get_formal ());
        Tootle.window.open_view (view);
        return false;
    }

}
