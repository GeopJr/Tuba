public class Tuba.Widgets.Audio.Visualizer : Gtk.Widget {
	const float SQR = 256;
	const int MAX_CIRCLE_HEIGHT = 512;
	const float ALPHA = 0.5f;

	Cairo.Context context;
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
				ALPHA
			};

			if (0.2126f * color.red + 0.7152f * color.green + 0.0722f * color.blue < 0.156862745f) {
			    color.red = float.min (1, color.red + 0.3f);
			    color.green = float.min (1, color.green + 0.3f);
			    color.blue = float.min (1, color.blue + 0.3f);
			}
		} else {
			#if ADW_1_6
				Adw.StyleManager.get_default ().notify["accent-color-rgba"].connect (update_accent_color);
				update_accent_color ();
			#else
				color = {
					120 / 255.0f,
					174 / 255.0f,
					237 / 255.0f,
					ALPHA
				};
			#endif
		}

		cover_texture = texture;
	}

	#if ADW_1_6
		private void update_accent_color () {
			color = Adw.StyleManager.get_default ().accent_color_rgba;
			color.alpha = ALPHA;
		}
	#endif

	public override void snapshot (Gtk.Snapshot snapshot) {
		int win_w = this.get_width ();
		int win_h = this.get_height ();

		int new_center_w = win_w / 2;
		int new_center_h = win_h / 2;

		var point = Graphene.Point ().init (new_center_w, new_center_h);
		snapshot.translate (point);

		float res = (float) level * (int.min (MAX_CIRCLE_HEIGHT, win_h) - SQR) + SQR;

        var rect = Graphene.Rect ().init (- res / 2, - res / 2, res, res);
        var rounded_rect = Gsk.RoundedRect ().init_from_rect (rect, 9999);

        snapshot.push_rounded_clip (rounded_rect);
        snapshot.append_color (color, rect);
        snapshot.pop ();

		if (cover_texture != null) {
			var cover_rect = Graphene.Rect ().init (- SQR / 2, - SQR / 2, SQR, SQR);
			var rounded_cover_rect = Gsk.RoundedRect ().init_from_rect (cover_rect, SQR);

        	snapshot.push_rounded_clip (rounded_cover_rect);
    		snapshot.append_texture (cover_texture, cover_rect);
        	snapshot.pop ();
		}
	}

	~Visualizer () {
		debug ("Destroying AudioVisualizer");
	}
}
