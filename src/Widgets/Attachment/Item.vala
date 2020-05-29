using Gtk;
using Gdk;

public class Tootle.Widgets.Attachment.Item : EventBox {

	public API.Attachment attachment { get; construct set; }
	
	private Cache.Reference? cached;

	public Item (API.Attachment obj) {
		Object (attachment: obj);
	}
	~Item () {
		cache.unload (cached);
	}
	
	construct {
		get_style_context ().add_class ("attachment");
		width_request = height_request = 128;
		hexpand = true;
		tooltip_text = attachment.description ?? _("No description is available");
		
		button_press_event.connect (on_clicked);
		
		show ();
		on_request ();
	}

	protected void on_request () {
		cached = null;
		on_redraw ();
		cache.load (attachment.preview_url, on_cache_result);
	}

	protected void on_redraw () {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		queue_draw_area (0, 0, w, h);
	}

	protected void on_cache_result (Cache.Reference? result) {
		cached = result;
		on_redraw ();
	}

	protected void download () {
        Desktop.download (attachment.url, path => {
        	app.toast (_("Attachment downloaded"));
        });
	}
	protected void open () {
        Desktop.download (attachment.url, path => {
        	Desktop.open_uri (path);
        });
	}

	public override bool draw (Cairo.Context ctx) {
		base.draw (ctx);
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		var style = get_style_context ();
		var border_radius = style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, style.get_state ()).get_int ();
		
		if (cached != null) {
			if (cached.loading) {
				Drawing.center (ctx, w, h, 32, 32);
				get_style_context ().render_activity (ctx, 0, 0, 32, 32);
			}
			else {
				var thumb = Drawing.make_thumbnail (cached.data, w, h);
				Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);
				Drawing.center (ctx, w, h, thumb.width, thumb.height);
				Gdk.cairo_set_source_pixbuf (ctx, thumb, 0, 0);
				ctx.fill ();
			}
		}
		
		return Gdk.EVENT_STOP;
	}

    protected virtual bool on_clicked (EventButton ev) {
		if (ev.button == 1) {
			open ();
			return true;
		}
        else if (ev.button == 3) {
        	var menu = new Gtk.Menu ();
        	
        	var item_open = new Gtk.MenuItem.with_label (_("Open"));
        	item_open.activate.connect (open);
        	menu.add (item_open);
        	
        	var item_download = new Gtk.MenuItem.with_label (_("Download"));
        	item_download.activate.connect (download);
        	menu.add (item_download);
        	
		    menu.show_all ();
		    menu.attach_widget = this;
		    menu.popup_at_pointer ();
        	return true;
        }
        return false;
    }

}
