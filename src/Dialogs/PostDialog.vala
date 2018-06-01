using Gtk;
using Tootle;

public class Tootle.PostDialog : Gtk.Dialog {

    private static PostDialog dialog;
    protected Gtk.TextView text;
    private Gtk.ScrolledWindow scroll;
    private Gtk.Label counter;
    private ImageToggleButton spoiler;
    private Gtk.MenuButton visibility;
    private Gtk.Button attach;
    private Gtk.Button cancel;
    private Gtk.Button publish;
    private AttachmentBox attachments;
    
    private Gtk.Revealer spoiler_revealer;
    private Gtk.Entry spoiler_text;
    
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
        if (in_reply_to != null)
            visibility_opt = in_reply_to.visibility;
        
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
        
        spoiler = new ImageToggleButton ("image-red-eye-symbolic");
        spoiler.tooltip_text = _("Spoiler Warning");
        spoiler.set_action ();
        spoiler.toggled.connect (() => {
            spoiler_revealer.reveal_child = spoiler.active;
            validate ();
        });
        
        cancel = add_button(_("Cancel"), 5) as Gtk.Button;
        cancel.clicked.connect(() => this.destroy ());
        publish = add_button(_("Toot!"), 5) as Gtk.Button;
        publish.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        publish.clicked.connect (() => {
            publish_post ();
        });
        
        spoiler_text = new Gtk.Entry ();
        spoiler_text.margin_start = 6;
        spoiler_text.margin_end = 6;
        spoiler_text.placeholder_text = _("Write your warning here");
        spoiler_text.changed.connect (validate);
        
        spoiler_revealer = new Gtk.Revealer ();
        spoiler_revealer.add (spoiler_text);
        
        text = new Gtk.TextView ();
        text.get_style_context ().add_class ("toot-text");
        text.wrap_mode = Gtk.WrapMode.WORD;
        text.accepts_tab = false;
        text.buffer.changed.connect (validate);
        
        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.min_content_height = 120;
        scroll.margin_start = 6;
        scroll.margin_end = 6;
        scroll.add (text);
        scroll.show_all ();
        
        attachments = new AttachmentBox (true);
        counter = new Gtk.Label ("500");
        
        actions.pack_start (counter, false, false, 6);
        actions.pack_end (spoiler, false, false, 6);
        actions.pack_end (visibility, false, false, 0);
        actions.pack_end (attach, false, false, 6);
        content.pack_start (spoiler_revealer, false, false, 6);
        content.pack_start (scroll, false, false, 6);
        content.pack_start (attachments, false, false, 6);
        content.set_size_request (350, 120);
        
        if (in_reply_to != null) {
            spoiler.active = in_reply_to.sensitive;
            var status_spoiler_text = in_reply_to.spoiler_text != null ? in_reply_to.spoiler_text : "";
            spoiler_text.set_text (status_spoiler_text);
        }
        
        show_all ();
        attachments.hide ();
        text.grab_focus ();
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
    
    private void validate () {
        var remain = 500 - text.buffer.text.length;
        if (spoiler.active)
            remain -= spoiler_text.buffer.text.length;
        
        counter.label = remain.to_string ();
        publish.sensitive = remain >= 0; 
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
        var pars = "?status=%s&visibility=%s".printf (Utils.encode (text.buffer.text), visibility_opt.to_string ());
        pars += attachments.get_uri_array ();    
        if (in_reply_to != null)
            pars += "&in_reply_to_id=%s".printf (in_reply_to.id.to_string ());
        
        if (spoiler.active) {
            pars += "&sensitive=true";
            pars += "&spoiler_text=" + Utils.encode (spoiler_text.buffer.text);
        }
        
        var url = "%s/api/v1/statuses%s".printf (Tootle.accounts.formal.instance, pars);
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
