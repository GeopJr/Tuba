public class Tuba.Widgets.Audio.Visualizer : Gtk.Widget {
	Cairo.Context context;
	const float SQR = 256;
	Gdk.RGBA color;
	Gdk.Texture cover_texture;

	double _level = 0.0;
	public double level {
		get { return _level; }
		set {
			_level = value;
			this.queue_draw ();
		}
	}

	construct {
		vexpand = true;
		hexpand = true;
	}

	public Visualizer (Gdk.Texture? texture = null, string? blurhash = null) {
		Cairo.ImageSurface surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, (int)SQR, (int)SQR);
		context = new Cairo.Context (surface);

		if (blurhash != null && blurhash != "") {
			var avg = Tuba.Blurhash.get_blurhash_average_color (blurhash);
			color = {
				avg.r / 255.0f,
				avg.g / 255.0f,
				avg.b / 255.0f,
				0.8f
			};

			if (0.2126f * color.red + 0.7152f * color.green + 0.0722f * color.blue < 0.156862745f) {
			    color.red = float.min (1, color.red + 0.3f);
			    color.green = float.min (1, color.green + 0.3f);
			    color.blue = float.min (1, color.blue + 0.3f);
			}
		} else {
			// TODO: ADW 1.6 StyleManager accent-color
			color = {
				120 / 255.0f,
				174 / 255.0f,
				237 / 255.0f,
				0.8f
			};
		}

		cover_texture = texture;
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		int win_w = this.get_width ();
		int win_h = this.get_height ();

		int new_center_w = win_w / 2;
		int new_center_h = win_h / 2;

		var point = Graphene.Point ().init (new_center_w, new_center_h);
		snapshot.translate (point);

		float res = (float) level * (win_h - SQR) + SQR;

        var rect = Graphene.Rect ().init (- res / 2, - res / 2, res, res);
        var rounded_rect = Gsk.RoundedRect ().init_from_rect (rect, 9999);

        snapshot.push_rounded_clip (rounded_rect);
        snapshot.append_color (color, rect);
        snapshot.pop ();

		if (cover_texture != null) {
			var cover_rect = Graphene.Rect ().init (- SQR / 2, - SQR / 2, SQR, SQR);
			var rounded_cover_rect = Gsk.RoundedRect ().init_from_rect (cover_rect, 9999);

        	snapshot.push_rounded_clip (rounded_cover_rect);
    		snapshot.append_texture (cover_texture, cover_rect);
        	snapshot.pop ();
		}
	}

	~Visualizer () {
		debug ("Destroying AudioVisualizer");
	}
}
