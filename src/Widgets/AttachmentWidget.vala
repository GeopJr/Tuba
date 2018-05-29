using Gtk;
using Gdk;

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
        
        destroy.connect (() => {
            if (image != null)
                image.clear ();
        });
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
                    Tootle.image_cache.load_scaled_image (attachment.preview_url, image);
                else
                    Tootle.image_cache.load_image (attachment.preview_url, image);
                grid.attach (image, 0, 0);
                label.hide ();
                break;
            default:
                label.label = _("Click to open %s media").printf (type);
                label.show ();
                break;
        }
        show ();
        button_press_event.connect(on_clicked);
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
            var url = "%s/api/v1/media".printf (Tootle.accounts.formal.instance);
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
    
    private bool on_clicked (EventButton ev){
        if (ev.button == 3)
            return open_menu (ev.button, ev.time);
        
        Tootle.Utils.open_url (attachment.url);
        return true;
    }
    
    public virtual bool open_menu (uint button, uint32 time) {
        var menu = new Gtk.Menu ();
        menu.selection_done.connect (() => {
            menu.detach ();
            menu.destroy ();
        });
        
        var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
        item_open_link.activate.connect (() => Utils.open_url (attachment.url));
        var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
        item_copy_link.activate.connect (() => Utils.copy (attachment.url));
        var item_download = new Gtk.MenuItem.with_label (_("Download"));
        item_download.activate.connect (() => Utils.download (attachment.url));
        menu.add (item_open_link);
        if (attachment.type != "unknown")
            menu.add (item_download);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (item_copy_link);
        
        menu.show_all ();
        menu.attach_widget = this;
        menu.popup (null, null, null, button, time);
        return true;
    }

}
