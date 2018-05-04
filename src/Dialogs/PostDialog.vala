using Gtk;
using Tootle;

public class Tootle.PostDialog : Gtk.Dialog {

    private static PostDialog dialog;
    protected Gtk.TextView text;
    private Gtk.Label counter;
    private Gtk.MenuButton visibility;
    private Gtk.Button publish;
    
    private StatusVisibility visibility_opt;
    protected int64? in_reply_to_id;

    public PostDialog (Gtk.Window? parent) {
        Object (
            border_width: 5,
            deletable: false,
            resizable: false,
            title: _("Toot"),
            transient_for: parent
        );
        visibility_opt = StatusVisibility.PUBLIC;
        
        var actions = get_action_area ().get_parent () as Gtk.Box;
        var content = get_content_area ();
        
        visibility = get_visibility_btn ();
        var close = add_button(_("Cancel"), 5) as Gtk.Button;
        close.clicked.connect(() => {
            this.destroy ();
        });
        publish = add_button(_("Toot!"), 5) as Gtk.Button;
        publish.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        publish.clicked.connect (() => {
            publish_post ();
        });
        
        text = new Gtk.TextView ();
        text.margin_start = 6;
        text.margin_end = 6;
        text.get_style_context ().add_class ("toot-text");
        text.hexpand = true;
        text.wrap_mode = Gtk.WrapMode.WORD;
        text.buffer.changed.connect (update_counter);
        
        counter = new Gtk.Label ("500");
        
        actions.pack_start (visibility, false, false, 6);
        actions.pack_start (counter, false, false, 6);
        content.pack_start (text, false, false, 0);
        content.set_size_request (300, 150);
    }
    
    private Gtk.MenuButton get_visibility_btn (){
        var button = new Gtk.MenuButton ();
        var icon = new Gtk.Image.from_icon_name (visibility_opt.get_icon (), Gtk.IconSize.SMALL_TOOLBAR);
        var menu = new Gtk.Popover (null);
        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        box.margin = 6;
        menu.add (box);
        button.direction = Gtk.ArrowType.DOWN;
        
        StatusVisibility[] opts = {StatusVisibility.PUBLIC, StatusVisibility.UNLISTED, StatusVisibility.PRIVATE, StatusVisibility.DIRECT};
        
        Gtk.RadioButton* first = null;
        foreach (StatusVisibility opt in opts){
            var item = new Gtk.RadioButton.with_label_from_widget (first, opt.get_desc ());
            if(first == null)
                first = item;
                
            item.toggled.connect (() => {
                visibility_opt = opt;
                button.remove (icon);
                icon = new Gtk.Image.from_icon_name (opt.get_icon (), Gtk.IconSize.SMALL_TOOLBAR);
                icon.show ();
                button.add (icon);
            });
            box.pack_start (item, false, false, 0);
        }
        
        box.show_all ();
        button.use_popover = true;
        button.popover = menu;
        button.valign = Gtk.Align.CENTER;
        button.add (icon);
        button.show ();
        
        return button;
    }
    
    private void update_counter (){
        var len = text.buffer.text.length;
        var remain = 500 - len;
        publish.sensitive = (remain >= 0); 
        
        counter.label = remain.to_string ();
    }
    
    public static void open (Gtk.Window? parent, string? text = null){
        if(dialog == null){
            dialog = new PostDialog (parent);
		    dialog.destroy.connect (() => {
		        dialog = null;
		    });
		    dialog.show_all ();
		    if (text != null)
		        dialog.text.buffer.text = text;
		}
		else
		    dialog.text.buffer.text += " " + text;
    }
    
    public static void open_reply (Gtk.Window? parent, Status status){
        if(dialog == null){
            open (parent);
            dialog.in_reply_to_id = status.id;
            dialog.text.buffer.text = "@%s ".printf (status.account.acct);
        }
    }
    
    public void publish_post(){
        var text_escaped = text.buffer.text.replace (" ", "%20");
        var pars = "?status=" + text_escaped;
        if (in_reply_to_id != null)
            pars += "&in_reply_to_id=" + in_reply_to_id.to_string ();
        pars += "&visibility=" + visibility_opt.to_string ();

        var msg = new Soup.Message("POST", Tootle.settings.instance_url + "/api/v1/statuses" + pars);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                var status = Status.parse (root);
                Tootle.window.home.prepend (status);
                this.destroy ();
            }
            catch (GLib.Error e) {
                warning ("Can't publish post.");
                warning (e.message);
            }
        });
    }

}
