using Gtk;
using GLib;

public class Tootle.Widgets.AttachmentGrid : Grid {

	private int counter = 0;
	private bool allow_editing;

	construct {
	    hexpand = true;
	}

	public AttachmentGrid (bool edit = false) {
		allow_editing = edit;
	}

	public void append (Attachment attachment) {
		var widget = new ImageAttachment (attachment);
		attach_widget (widget);
	}
	public void append_widget (ImageAttachment widget) {
		attach_widget (widget);
	}

	private void attach_widget (ImageAttachment widget) {
	    attach (widget, counter++, 1);
	    column_spacing = row_spacing = 12;
	    show_all ();
	}

    public void pack (Attachment[] attachments) {
        clear ();
        var len = attachments.length;

        if (len == 1) {
            var widget = new ImageAttachment (attachments[0]);
            attach_widget (widget);
            widget.fill_parent ();
        }
        else {
            foreach (Attachment attachment in attachments) {
                append (attachment);
            }
        }
    }

	private void clear () {
		forall (widget => widget.destroy ());
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
                var widget = new ImageAttachment.upload (uri);
                append_widget (widget);
            }
        }
        chooser.close ();
    }

    public string get_uri_array () {
        var str = "";
        get_children ().@foreach (w => {
            var widget = (ImageAttachment) w;
            if (widget.attachment != null)
                str += "&media_ids[]=%lld".printf (widget.attachment.id);
        });
        return str;
    }

}
