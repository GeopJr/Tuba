using Gtk;
using Tootle;

public class Tootle.PostDialog : Gtk.Dialog {

    private static PostDialog dialog;
    protected Gtk.TextView text;
    private Gtk.ScrolledWindow scroll;
    private Gtk.Label counter;
    private Gtk.MenuButton visibility;
    private Gtk.Button attach;
    private Gtk.Button cancel;
    private Gtk.Button publish;
    private AttachmentBox attachments;
    
    protected Status? in_reply_to;
    protected StatusVisibility visibility_opt = StatusVisibility.PUBLIC;

    public PostDialog (Status? status = null) {
        Object (
            border_width: 6,
            deletable: false,
            resizable: false,
            title: _("Toot"),
            transient_for: Tootle.window
        );
        in_reply_to = status;
        if (status != null)
            visibility_opt = status.visibility;
        
        var actions = get_action_area ().get_parent () as Gtk.Box;
        var content = get_content_area ();
        get_action_area ().hexpand = false;
        
        visibility = get_visibility_btn ();
        visibility.tooltip_text = _("Post Visibility");
        visibility.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        visibility.get_style_context ().remove_class ("image-button");
        visibility.can_default = false;
        visibility.set_focus_on_click (false);
        attach = new Gtk.Button.from_icon_name ("mail-attachment-symbolic");
        attach.tooltip_text = _("Add Media");
        attach.valign = Gtk.Align.CENTER;
        attach.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        attach.get_style_context ().remove_class ("image-button");
        attach.can_default = false;
        attach.set_focus_on_click (false);
        attach.clicked.connect (() => attachments.select ());
        
        cancel = add_button(_("Cancel"), 5) as Gtk.Button;
        cancel.clicked.connect(() => this.destroy ());
        publish = add_button(_("Toot!"), 5) as Gtk.Button;
        publish.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        publish.clicked.connect (() => {
            publish_post ();
        });
        
        text = new Gtk.TextView ();
        text.get_style_context ().add_class ("toot-text");
        text.wrap_mode = Gtk.WrapMode.WORD;
        text.buffer.changed.connect (update_counter);
        
        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.min_content_height = 150;
        scroll.margin_start = 6;
        scroll.margin_end = 6;
        scroll.add (text);
        scroll.show_all ();
        
        attachments = new AttachmentBox (true);
        counter = new Gtk.Label ("500");
        
        actions.pack_start (counter, false, false, 6);
        actions.pack_end (visibility, false, false, 0);
        actions.pack_end (attach, false, false, 6);
        content.pack_start (scroll, false, false, 6);
        content.pack_start (attachments, false, false, 6);
        content.set_size_request (350, 150);
        
        show_all ();
        attachments.hide ();
    }
    
    private Gtk.MenuButton get_visibility_btn () {
        var button = new Gtk.MenuButton ();
        var menu = new Gtk.Popover (null);
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.margin = 6;
        menu.add (box);
        button.direction = Gtk.ArrowType.DOWN;
        button.image = new Gtk.Image.from_icon_name (visibility_opt.get_icon (), Gtk.IconSize.BUTTON);
        
        StatusVisibility[] opts = {StatusVisibility.PUBLIC, StatusVisibility.UNLISTED, StatusVisibility.PRIVATE, StatusVisibility.DIRECT};
        
        Gtk.RadioButton* first = null;
        foreach (StatusVisibility opt in opts){
            var item = new Gtk.RadioButton.with_label_from_widget (first, opt.get_desc ());
            if (first == null)
                first = item;
                
            item.toggled.connect (() => {
                visibility_opt = opt;
                (button.image as Gtk.Image).icon_name = visibility_opt.get_icon ();
            });
            item.active = visibility_opt == opt;
            box.pack_start (item, false, false, 0);
        }
        
        box.show_all ();
        button.use_popover = true;
        button.popover = menu;
        button.valign = Gtk.Align.CENTER;
        button.show ();
        return button;
    }
    
    private void update_counter () {
        var len = text.buffer.text.length;
        var remain = 500 - len;
        publish.sensitive = (remain >= 0); 
        
        counter.label = remain.to_string ();
    }
    
    public static void open (string? text = null, Status? reply_to = null) {
        if (dialog == null){
            dialog = new PostDialog (reply_to);
		    dialog.destroy.connect (() => dialog = null);
		    if (text != null)
		        dialog.text.buffer.text = text;
		}
		else if (text != null)
		    dialog.text.buffer.text += " " + text;
    }
    
    public static void open_reply (Status reply_to) {
        if(dialog != null)
            return;
        
        open (null, reply_to);
        dialog.text.buffer.text = "@%s ".printf (reply_to.account.acct);
    }
    
    public void publish_post () {
        var pars = "?status=%s&visibility=%s".printf (Soup.URI.encode (text.buffer.text, null), visibility_opt.to_string ());
        pars += attachments.get_uri_array ();    
        if (in_reply_to != null)
            pars += "&in_reply_to_id=%s".printf (in_reply_to.id.to_string ());
        
        var url = "%s/api/v1/statuses%s".printf (Tootle.settings.instance_url, pars);
        var msg = new Soup.Message("POST", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try {
                var root = Tootle.network.parse (mess);
                var status = Status.parse (root);
                debug ("Posted: %s", status.id.to_string ()); //TODO: Live updates
                this.destroy ();
            }
            catch (GLib.Error e) {
                warning ("Can't publish post.");
                warning (e.message);
            }
        });
    }

}
