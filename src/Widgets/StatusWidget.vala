using Gtk;
using Gdk;
using Granite;

public class Tootle.StatusWidget : Gtk.EventBox {
    
    public Status status;
    public bool is_notification = false;
    
    public Gtk.Separator? separator;
    public Gtk.Grid grid;
    public Granite.Widgets.Avatar avatar;
    private const int avatar_size = 32;
    public Gtk.Label title_user;
    public Gtk.Label title_date;
    public Gtk.Label title_acct;
    public Gtk.Revealer revealer;
    public Tootle.RichLabel content_label;
    public Tootle.RichLabel? content_spoiler;
    public Gtk.Button? spoiler_button;
    public Gtk.Box title_box;
    public AttachmentBox attachments;
    public Gtk.Box counters;
    public Gtk.Label reblogs;
    public Gtk.Label favorites;
    public ImageToggleButton reblog;
    public ImageToggleButton favorite;
    public ImageToggleButton reply;

    construct {
        grid = new Gtk.Grid ();
    
        avatar = new Granite.Widgets.Avatar.with_default_icon (32);
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
        title_date.opacity = 0.5;
        title_date.ellipsize = Pango.EllipsizeMode.END;
        title_box.pack_end (title_date, false, false, 0);
        title_box.show_all ();
        
        content_label = new RichLabel ("");
        content_label.wrap_words ();
        
        attachments = new AttachmentBox ();

        var revealer_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);    
        revealer_box.margin_end = 12;
        revealer_box.add (content_label);    
        revealer_box.add (attachments);    
        revealer = new Revealer ();
        revealer.reveal_child = true;
        revealer.add (revealer_box);
        
        reblogs = new Gtk.Label ("0");
        favorites = new Gtk.Label ("0");
        
        reblog = new ImageToggleButton ("go-up-symbolic");
        reblog.set_action ();
        reblog.tooltip_text = _("Boost");
        reblog.toggled.connect (() => {
            if (reblog.sensitive)
                this.status.get_formal ().set_reblogged (reblog.get_active ());
        });
        favorite = new ImageToggleButton ("help-about-symbolic");
        favorite.set_action ();
        favorite.tooltip_text = _("Favorite");
        favorite.toggled.connect (() => {
            if (favorite.sensitive)
                this.status.get_formal ().set_favorited (favorite.get_active ());
        });
        reply = new ImageToggleButton ("edit-undo-symbolic");
        reply.set_action ();
        reply.tooltip_text = _("Reply");
        reply.toggled.connect (() => {
            reply.set_active (false);
            PostDialog.open_reply (status.get_formal ());
        });
        
        counters = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        counters.margin_top = 6;
        counters.margin_bottom = 6;
        counters.add (reblog);
        counters.add (reblogs);
        counters.add (favorite);
        counters.add (favorites);
        counters.add (reply);
        counters.show_all ();
        
        add (grid);
        grid.attach (avatar, 1, 1, 1, 4);
        grid.attach (title_box, 2, 2, 1, 1);
        grid.attach (revealer, 2, 4, 1, 1);
        grid.attach (counters, 2, 5, 1, 1);
        show_all ();
    
        this.button_press_event.connect (on_clicked);
    }

    public StatusWidget (ref Status status) {
        this.status = status;
        this.status.updated.connect (rebind);
        
        if (this.status.reblog != null) {
            var image = new Gtk.Image.from_icon_name("go-up-symbolic", Gtk.IconSize.BUTTON);
            image.halign = Gtk.Align.END;
            image.margin_end = 6;
            image.margin_top = 6;
            image.show ();
            
            var label_text = _("<a href=\"%s\"><b>%s</b></a> boosted").printf (this.status.account.url, this.status.account.display_name);
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
        
        if (status.get_formal ().attachments != null) {
            attachments.clear ();
            foreach (Attachment attachment in status.get_formal ().attachments)
                attachments.append (attachment);
        }
        else
            attachments.destroy ();
        
        destroy.connect (() => {
            avatar.show_default (avatar_size);
            if(separator != null)
                separator.destroy ();
        });
        
        Tootle.network.status_removed.connect (id => {
            if (id == this.status.id)
                destroy ();
        });
        
        rebind ();
    }
    
    public void highlight () {
        grid.get_style_context ().add_class ("card");
        grid.margin_bottom = 6;
    }
    
    public void rebind () {
        var formal = status.get_formal ();
        
        title_user.label = "<b>%s</b>".printf (Utils.escape_entities (formal.account.display_name));
        title_acct.label = "@" + formal.account.acct;
        content_label.label = formal.content;
        content_label.mentions = formal.mentions;
        
        var datetime = parse_date_iso8601 (formal.created_at);
        title_date.label = Granite.DateTime.get_relative_datetime (datetime);
        
        reblogs.label = formal.reblogs_count.to_string ();
        favorites.label = formal.favourites_count.to_string ();
        
        reblog.sensitive = false;
        reblog.active = formal.reblogged;
        reblog.sensitive = true;
        favorite.sensitive = false;
        favorite.active = formal.favorited;
        favorite.sensitive = true;
        
        if (formal.visibility == StatusVisibility.DIRECT) {
            reblog.sensitive = false;
            reblog.icon.icon_name = formal.visibility.get_icon ();
            reblog.tooltip_text = _("This post can't be boosted");
        }
        
        Tootle.network.load_avatar (formal.account.avatar, avatar, avatar_size);
    }

    public bool is_spoiler () {
        return this.status.get_formal ().spoiler_text != null || this.status.get_formal ().sensitive;
    }
    
    private GLib.DateTime? parse_date_iso8601 (string date) {
        var timeval = GLib.TimeVal ();
        if (timeval.from_iso8601 (date))
            return new GLib.DateTime.from_timeval_local (timeval);
        
        return null;
    }
    
    public bool open_account () {
        var view = new AccountView (status.get_formal ().account);
        Tootle.window.open_view (view);
        return true;
    }
    
    public bool open (EventButton ev) {
        var formal = status.get_formal ();
        var view = new StatusView (ref formal);
        Tootle.window.open_view (view);
        return true;
    }
    
    private bool on_clicked (EventButton ev) {
        if (ev.button == 3)
            return open_menu (ev.button, ev.time);
        else
            return false;
    }
    
    public virtual bool open_menu (uint button, uint32 time) {
        var menu = new Gtk.Menu ();
        menu.selection_done.connect (() => {
            menu.detach ();
            menu.destroy ();
        });
        
        var is_muted = status.muted;
        var item_muting = new Gtk.MenuItem.with_label (is_muted ? _("Unmute Conversation") : _("Mute Conversation"));
        item_muting.activate.connect (() => status.set_muted (!is_muted));
        var item_delete = new Gtk.MenuItem.with_label (_("Delete"));
        item_delete.activate.connect (() => status.poof ());
        var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
        item_open_link.activate.connect (() => Utils.open_url (status.url));
        var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
        item_copy_link.activate.connect (() => Utils.copy (status.url));
        var item_copy = new Gtk.MenuItem.with_label (_("Copy Text"));
        item_copy.activate.connect (() => {
            var sanitized = Utils.escape_html (status.content);
            Utils.copy (sanitized);
        });
        
        if (this.status.is_owned ()) {
            menu.add (item_delete);
            menu.add (new Gtk.SeparatorMenuItem ());
        }
        
        if (this.is_notification)
            menu.add (item_muting);
        menu.add (item_open_link);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (item_copy_link);
        menu.add (item_copy);
        
        menu.show_all ();
        menu.attach_widget = this;
        menu.popup (null, null, null, button, time);
        return true;
    }

}
