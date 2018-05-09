using Gtk;
using GLib;

public class Tootle.AttachmentBox : Gtk.ScrolledWindow {

    private Gtk.Box box;
    private bool edit_mode;
    private int64[] ids;

    construct {
        box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        box.hexpand = true;
        add (box);
        show_all ();
    }

    public AttachmentBox (bool edit = false) {
        Object ();
        edit_mode = edit;
        vscrollbar_policy = Gtk.PolicyType.NEVER;
    }
    
    public void clear () {
        box.forall (widget => widget.destroy ());
    }
    
    public void append (Attachment attachment) {
        var widget = new AttachmentWidget (attachment);
        box.add (widget);
    }
    
    public void select () {
        var filter = new Gtk.FileFilter ();
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/png");
        filter.add_mime_type ("image/gif");
        filter.add_mime_type ("video/webm");
        filter.add_mime_type ("video/mp4");
        
        var chooser = new Gtk.FileChooserDialog (
            _("Select media files to add"),
            null,
            Gtk.FileChooserAction.OPEN,
            _("_Cancel"),
            Gtk.ResponseType.CANCEL,
            _("_Open"),
            Gtk.ResponseType.ACCEPT);
        
        chooser.select_multiple = true;
        chooser.set_filter (filter);
        
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            show ();
            foreach (unowned string uri in chooser.get_uris ()) {
                var widget = new AttachmentWidget.upload (uri);
                widget.uploaded.connect (id => ids += id);
                box.pack_start (widget, false, false, 6);
            }
        }
        chooser.close ();
    }
    
    public string get_uri_array () {
        var str = "";
        foreach (int64 item in ids)
            str += "&media_ids[]=" + item.to_string ();
        return str;
    }

}
