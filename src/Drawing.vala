using Gdk;
using GLib;

public class Tootle.Drawing {

	public static void draw_rounded_rect (Cairo.Context ctx, double x, double y, double w, double h, double r) {
		double degr = Math.PI / 180.0;
		ctx.new_sub_path ();
		ctx.arc (x + w - r, y + r, r, -90 * degr, 0 * degr);
		ctx.arc (x + w - r, y + h - r, r, 0 * degr, 90 * degr);
		ctx.arc (x + r, y + h - r, r, 90 * degr, 180 * degr);
		ctx.arc (x + r, y + r, r, 180 * degr, 270 * degr);
		ctx.close_path ();
	}

}
