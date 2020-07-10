using Gtk;
using Gdk;

public class Tootle.Widgets.Avatar : EventBox {

	public string? url { get; set; }
	public int size { get; set; default = 48; }

	private Cache.Reference? cached;

	construct {
		get_style_context ().add_class ("avatar");
		notify["url"].connect (on_url_updated);
		notify["size"].connect (on_redraw);
		// Screen.get_default ().monitors_changed.connect (on_redraw);
		on_url_updated ();
	}

	public Avatar (int size = this.size) {
		Object (size: size);
		on_redraw ();
	}

	~Avatar () {
		notify["url"].disconnect (on_url_updated);
		// Screen.get_default ().monitors_changed.disconnect (on_redraw);
		cache.unload (cached);
	}

	private void on_url_updated () {
		if (cached != null)
			cache.unload (cached);
		cached = null;
		on_redraw ();
		cache.load (url, on_cache_result);
	}

	private void on_cache_result (Cache.Reference? result) {
		cached = result;
		on_redraw ();
	}

	public int get_scaled_size () {
		return size; //return size * get_scale_factor ();

	private void on_redraw () {
		set_size_request (get_scaled_size (), get_scaled_size ());
		queue_draw_area (0, 0, size, size);
	}

	public override bool draw (Cairo.Context ctx) {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		var style = get_style_context ();
		var border_radius = style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, style.get_state ()).get_int ();
		Pixbuf pixbuf;

		Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);
		if (cached != null && !cached.loading) {
			pixbuf = cached.data.scale_simple (get_scaled_size (), get_scaled_size (), InterpType.BILINEAR);
		}
		else {
			pixbuf = IconTheme.get_default ()
				.load_icon_for_scale ("avatar-default", get_scaled_size (), get_scale_factor (), IconLookupFlags.GENERIC_FALLBACK);
		}
		Gdk.cairo_set_source_pixbuf (ctx, pixbuf, 0, 0);
		ctx.fill ();

		return Gdk.EVENT_STOP;
	}

}
