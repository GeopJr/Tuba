using Gtk;

public class Tootle.AttachmentWidget : Gtk.EventBox {

    public abstract signal void uploaded (int64 id);
    public abstract signal void removed (int64 id);

    Attachment? attachment;
    private bool editable = false;
    
    public Gtk.Label label;
    Gtk.Grid grid;
    Gtk.Image? image;

    construct {
        set_size_request (64, 64);
        grid = new Gtk.Grid ();
        get_style_context ().add_class ("attachment");
        
        label = new Gtk.Label ("");
        label.wrap = true;
        label.vexpand = true;
        label.margin_start = label.margin_end = 8;
        grid.attach (label, 0, 0);
        
        add (grid);
        grid.show ();
        label.hide ();
    }

    public AttachmentWidget (Attachment att) {
        attachment = att;
        rebind ();
    }
    
    public void rebind () {
        var type = attachment.type;
        switch (type){
            case "image":
                image = new Gtk.Image ();
                image.vexpand = true;
                image.margin = 3;
                image.valign = Gtk.Align.CENTER;
                image.show ();
                if (editable)
                    Tootle.network.load_scaled_image (attachment.preview_url, image);
                else
                    Tootle.network.load_image (attachment.preview_url, image);
                grid.attach (image, 0, 0);
                label.hide ();
                break;
            default:
                label.label = _("Click to open %s media").printf (type);
                label.show ();
                break;
        }
        show ();
        button_press_event.connect(() => {
            if (!editable)
                Tootle.Utils.open_url (attachment.url);
            return true;
        });
    }
    
    public AttachmentWidget.upload (string uri) {
        try {
            GLib.File file = File.new_for_uri (uri);
            uint8[] contents;
            file.load_contents (null, out contents, null);
            var type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
            var mime = type.get_content_type ();
            
            debug ("Uploading %s (%s)", uri, mime);
            label.label = _("Uploading file...");
            label.show ();
            show ();
            
            var buffer = new Soup.Buffer.take (contents);
            var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
            multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);
            var url = "%s/api/v1/media".printf (Tootle.settings.instance_url);
            var msg = Soup.Form.request_new_from_multipart (url, multipart);
            
            Tootle.network.queue(msg, (sess, mess) => {
                var root = Tootle.network.parse (mess);
                attachment = Attachment.parse (root);
                editable = true;
                rebind ();
                
                debug ("Uploaded media: %lld", attachment.id);
                uploaded (attachment.id);
            });
        }
        catch (Error e) {
            error (e.message);
            Tootle.app.error (_("File read error"), _("Can't read file %s: %s").printf (uri, e.message));
        }
    }

}
