using Gtk;

public class Tootle.TootDialog : Gtk.Dialog {

    private static TootDialog dialog;
    private Gtk.TextView text;
    private Gtk.Label counter;

    public TootDialog (Gtk.Window? parent) {
        Object (
            border_width: 5,
            deletable: false,
            resizable: false,
            title: _("Toot"),
            transient_for: parent
        );
        var actions = get_action_area().get_parent() as Gtk.Box;
        var content = get_content_area();
        
        var close = add_button(_("Cancel"), 5) as Gtk.Button;
        close.clicked.connect(() => {
            this.destroy ();
        });
        
        var publish = add_button(_("Toot!"), 5) as Gtk.Button;
        publish.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        
        text = new Gtk.TextView();
        text.margin_start = 6;
        text.margin_end = 6;
        text.get_style_context ().add_class ("toot-text");
        text.hexpand = true;
        text.wrap_mode = Gtk.WrapMode.WORD;
        text.buffer.changed.connect(update_counter);
        
        counter = new Gtk.Label ("500");
        
        actions.pack_start (counter, false, false, 6);
        content.pack_start (text, false, false, 0);
        content.set_size_request (300, 100);
    }
    
    private void update_counter(){
        var len = text.buffer.text.length;
        
        counter.label = (500 - len).to_string ();
    }
    
    public static void open(Gtk.Window? parent){
        if(dialog == null){
            dialog = new TootDialog (parent);
		    dialog.destroy.connect (() => {
		        dialog = null;
		    });
		    dialog.show_all ();
		}
    }

}
