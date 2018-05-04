using Gtk;

public class Tootle.AttachmentWidget : Gtk.EventBox {

    Attachment attachment;
    Gtk.Grid grid;
    Gtk.Label? label;
    Gtk.Image? image;

    construct {
        margin_top = 6;
        grid = new Gtk.Grid ();
        get_style_context ().add_class ("attachment");
        add (grid);
    }

    public AttachmentWidget (Attachment att) {
        attachment = att;
        var type = attachment.type;
        
        switch (type){
            case "image":
                image = new Gtk.Image ();
                image.vexpand = true;
                image.margin = 3;
                image.valign = Gtk.Align.CENTER;
                Tootle.cache.load_image (attachment.preview_url, image);
                grid.attach (image, 0, 0);
                break;
            default:
                label = new Gtk.Label (_("Click to open %s media").printf (type));
                label.margin = 16;
                grid.attach (label, 0, 0);
                break;
        }
        
        button_press_event.connect(() => {
            Tootle.Utils.open_url (attachment.url);
            return true;
        });
        show_all ();
    }

}
