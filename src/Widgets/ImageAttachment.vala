using Gtk;
using Gdk;

public class Tootle.Widgets.ImageAttachment : Gtk.DrawingArea {

	public Attachment? attachment;
	private bool editable = false;
	private bool fill = false;

	private Pixbuf? pixbuf = null;
	private static Pixbuf? pixbuf_error;
	private int center_x = 0;
	private int center_y = 0;

	private Soup.Message? image_request;

	construct {
		if (pixbuf_error == null)
			pixbuf_error = IconTheme.get_default ().load_icon ("image-missing", 32, IconLookupFlags.GENERIC_FALLBACK);

		hexpand = true;
		vexpand = true;
		add_events (EventMask.BUTTON_PRESS_MASK);
		draw.connect (on_draw);
		button_press_event.connect (on_clicked);
	}

	~ImageAttachment () {
		network.cancel_request (image_request);
	}

	public ImageAttachment (Attachment obj) {
		attachment = obj;
		image_request = network.load_pixbuf (attachment.preview_url, on_ready);
		set_size_request (32, 128);
		show_all ();
	}

    public ImageAttachment.upload (string uri) {
    	halign = Align.START;
    	valign = Align.START;
    	set_size_request (100, 100);
    	show_all ();
        try {
            GLib.File file = File.new_for_uri (uri);
            uint8[] contents;
            file.load_contents (null, out contents, null);
            var type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
            var mime = type.get_content_type ();

            info ("Uploading %s (%s)", uri, mime);
            show ();

            var buffer = new Soup.Buffer.take (contents);
            var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
            multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);
            var url = "%s/api/v1/media".printf (accounts.formal.instance);
            var msg = Soup.Form.request_new_from_multipart (url, multipart);

            network.queue (msg, (sess, mess) => {
                var root = network.parse (mess);
                attachment = Attachment.parse (root);
                editable = true;
                invalidate ();
                network.load_pixbuf (attachment.preview_url, on_ready);
                info ("Uploaded media: %lld", attachment.id);
            });
        }
        catch (Error e) {
            error (e.message);
            app.error (_("File read error"), _("Can't read file %s: %s").printf (uri, e.message));
        }
    }

	private void on_ready (Pixbuf? result) {
		if (result == null)
			result = pixbuf_error;

		pixbuf = result;
		invalidate ();
	}

	private void invalidate () {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		if (fill) {
			var h_scaled = (pixbuf.height * w) / pixbuf.width;
			if (h_scaled > pixbuf.height) {
				halign = Align.START;
				set_size_request (pixbuf.width, pixbuf.height);
			}
			else {
				halign = Align.FILL;
				set_size_request (1, h_scaled);
			}
		}
		queue_draw_area (0, 0, w, h);
	}

	private void calc_center (int w, int h, int size_w, int size_h, Cairo.Context? ctx = null) {
		center_x = w/2 - size_w/2;
		center_y = h/2 - size_h/2;

		if (ctx != null)
			ctx.translate (center_x, center_y);
	}

	public void fill_parent () {
		fill = true;
		size_allocate.connect (on_size_changed);
		on_size_changed ();
	}

	public void on_size_changed () {
		if (fill && pixbuf != null)
			invalidate ();
	}

	private bool on_draw (Widget widget, Cairo.Context ctx) {
		var w = widget.get_allocated_width ();
		var h = widget.get_allocated_height ();
		if (halign == Align.START) {
			w = pixbuf.width;
			h = pixbuf.height;
		}

		//Draw frame
		ctx.set_source_rgba (1, 1, 1, 1);
		Drawing.draw_rounded_rect (ctx, 0, 0, w, h, 4);
		ctx.fill ();

		//Draw image, spinner or an error icon
		if (pixbuf != null) {
			var thumbnail = Drawing.make_pixbuf_thumbnail (pixbuf, w, h, fill);
			Drawing.draw_rounded_rect (ctx, 0, 0, w, h, 4);
			calc_center (w, h, thumbnail.width, thumbnail.height, ctx);
			Gdk.cairo_set_source_pixbuf (ctx, thumbnail, 0, 0);
			ctx.fill ();
		}
		else {
			calc_center (w, h, 32, 32, ctx);
			set_state_flags (StateFlags.CHECKED, false); //Y U NO SPIN
			get_style_context ().render_activity (ctx, 0, 0, 32, 32);
		}

		return false;
	}

    private bool on_clicked (EventButton ev){
    	switch (ev.button) {
    		case 3:
    			return open_menu (ev.button, ev.time);
    		case 1:
    			Desktop.open_uri (attachment.url);
    			return true;
    	}
    	return false;
    }

    public virtual bool open_menu (uint button, uint32 time) {
        var menu = new Gtk.Menu ();

        if (editable && attachment != null) {
            var item_remove = new Gtk.MenuItem.with_label (_("Remove"));
            item_remove.activate.connect (() => destroy ());
            menu.add (item_remove);
            menu.add (new Gtk.SeparatorMenuItem ());
        }

        var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
        item_open_link.activate.connect (() => Desktop.open_uri (attachment.url));
        var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
        item_copy_link.activate.connect (() => Desktop.copy (attachment.url));
        var item_download = new Gtk.MenuItem.with_label (_("Download"));
        item_download.activate.connect (() => Desktop.download_file (attachment.url));
        menu.add (item_open_link);
        if (attachment.type != "unknown")
            menu.add (item_download);
        menu.add (new Gtk.SeparatorMenuItem ());
        menu.add (item_copy_link);

        menu.show_all ();
        menu.attach_widget = this;
        menu.popup_at_pointer ();
        return true;
    }

}
