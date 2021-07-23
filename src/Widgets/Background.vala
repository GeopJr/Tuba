using Gdk;

// This widget fits a Paintable inside its bounds without letterboxing.
public class Tootle.Widgets.Background : Gtk.Widget {

	public Paintable? paintable { get; set; default = null; }

	construct {
		add_css_class ("header-image");
		notify["paintable"].connect (() => {
			this.queue_draw ();
		});

		overflow = Gtk.Overflow.HIDDEN;
	}

	public Graphene.Size widget_size {
		get {
			return Graphene.Size () {
				width = get_width (),
				height = get_height ()
			};
		}
	}
	public Graphene.Size image_size {
		get {
			if (paintable == null)
				return Graphene.Size.zero ();

			return Graphene.Size () {
				width = paintable.get_intrinsic_width (),
				height = paintable.get_intrinsic_height ()
			};
		}
	}

	Graphene.Rect get_bounds () {
		var bounds = Graphene.Rect ();
		bounds.init (0, 0, widget_size.width, widget_size.height);
		return bounds;
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (paintable == null)
			return;

		// Get ratio
		float image_ratio;
		var xscale = (float) widget_size.width / image_size.width;
		var yscale = (float) widget_size.height / image_size.height;
		if (xscale > yscale)
			image_ratio = xscale;
		else
			image_ratio = yscale;

		// Start drawing
		snapshot.save ();

		// Clip image
		snapshot.push_clip (get_bounds ());

		// Center the image
		var result_h = image_size.height * image_ratio;
		var result_w = image_size.width * image_ratio;
		var offset_y = (widget_size.height - result_h) / 2;
		var offset_x = (widget_size.width - result_w) / 2;

		var offset = Graphene.Point ();
		offset.init (offset_x, offset_y);
		snapshot.translate (offset);

		// Scale and draw the paintable
		snapshot.scale (image_ratio, image_ratio);
		paintable.snapshot (snapshot, image_size.width, image_size.height);

		// Clean-up
		snapshot.pop ();
		snapshot.restore ();

		base.snapshot (snapshot);
	}

}
