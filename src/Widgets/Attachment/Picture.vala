using Gtk;
using Gdk;

public class Tootle.Widgets.Attachment.Picture : DrawingArea {

	public string url { get; set; }

	Cache.Reference? cached;

	construct {
		hexpand = vexpand = true;
		get_style_context ().add_class ("pic");
	}

	public class Picture (string url) {
		Object (url: url);
	}
	~Picture () {
		cache.unload (ref cached);
	}

	public void on_request () {
		cached = null;
		on_redraw ();
		cache.load (url, on_cache_update);
	}

	void on_cache_update (Cache.Reference? result) {
		cached = result;
		if (cached != null)
			visible = !cached.loading;
		on_redraw ();
	}

	void on_redraw () {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		queue_draw_area (0, 0, w, h);
	}

	float get_ratio (int w, int h) {
		var ow = cached.data.get_width ();
		var oh = cached.data.get_height ();
		var xscale = (float) w / ow;
		var yscale = (float) h / oh;

		if (xscale > yscale)
			return xscale;
		else
			return yscale;
	}

	public override bool draw (Cairo.Context ctx) {
		var w = get_allocated_width ();
		var h = get_allocated_height ();
		var style = get_style_context ();
		var border_radius = style.get_property (Gtk.STYLE_PROPERTY_BORDER_RADIUS, style.get_state ()).get_int ();

		if (cached != null) {
			if (!cached.loading) {
				Cairo.Surface surface = Gdk.cairo_surface_create_from_pixbuf (cached.data, 1, null);

				ctx.save ();
				Drawing.draw_rounded_rect (ctx, 0, 0, w, h, border_radius);

				//Proportionally scale to fit into the allocated container
				var ratio = get_ratio (w, h);
				ctx.scale (ratio, ratio);

				//Center the result
				var oh = cached.data.get_height ();
				var result_h = oh*ratio;
				var offset_y = (h - result_h) / 2;

				var ow = cached.data.get_width ();
				var result_w = ow*ratio;
				var offset_x = (w - result_w) / 2;

				ctx.translate (offset_x, offset_y);

				//Draw it
				ctx.set_source_surface (surface, 0, 0);
				ctx.fill ();
				ctx.restore ();
			}
		}

		return false;
	}

}
