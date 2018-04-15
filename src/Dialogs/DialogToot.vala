using Gtk;
using Tootle;

public class Tootle.TootDialog : Gtk.Dialog {

    private static TootDialog dialog;
    private Gtk.TextView text;
    private Gtk.Label counter;
    private Gtk.MenuButton visibility;
    
    private StatusVisibility visibility_opt;

    public TootDialog (Gtk.Window? parent) {
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
        var publish = add_button(_("Toot!"), 5) as Gtk.Button;
        publish.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        publish.clicked.connect (() => {
            this.destroy (); //TODO: actually publish toots
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
        content.set_size_request (300, 100);
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
        
        counter.label = (500 - len).to_string ();
    }
    
    public static void open (Gtk.Window? parent){
        if(dialog == null){
            dialog = new TootDialog (parent);
		    dialog.destroy.connect (() => {
		        dialog = null;
		    });
		    dialog.show_all ();
		}
    }

}
