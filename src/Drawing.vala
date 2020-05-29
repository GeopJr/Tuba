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

	public static void center (Cairo.Context ctx, int w, int h, int tw, int th) {
		var cx = w/2 - tw/2;
		var cy = h/2 - th/2;
		ctx.translate (cx, cy);
	}

	public static Pixbuf make_thumbnail (Pixbuf pb, int view_w, int view_h) {
		if (view_w >= pb.width && view_h >= pb.height)
			return pb;

		double ratio_x = (double) view_w / (double) pb.width;
		double ratio_y = (double) view_h / (double) pb.height;
		double ratio = ratio_x < ratio_y ? ratio_x : ratio_y;

		return pb.scale_simple (
			(int) (pb.width * ratio),
			(int) (pb.height * ratio),
			InterpType.BILINEAR);
	}

}
