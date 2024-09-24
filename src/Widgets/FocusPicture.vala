public class Tuba.Widgets.FocusPicture : Gtk.Widget, Gtk.Buildable, Gtk.Accessible {
	ulong paintable_invalidate_contents_signal = 0;
	ulong paintable_invalidate_size_signal = 0;

	double _focus_x = 0.0;
	public double focus_x {
		get { return _focus_x; }
		set {
			_focus_x = value.clamp (-1.0, 1.0);
			if (_paintable != null) this.queue_draw ();
		}
	}

	double _focus_y = 0.0;
	public double focus_y {
		get { return _focus_y; }
		set {
			_focus_y = value.clamp (-1.0, 1.0);
			if (_paintable != null) this.queue_draw ();
		}
	}

	string? _alternative_text = null;
	public string? alternative_text {
		get { return _alternative_text; }
		set {
			if (value == _alternative_text) return;

			_alternative_text = value;
			if (value == null) _alternative_text = "";

			this.update_property (Gtk.AccessibleProperty.DESCRIPTION, _alternative_text, -1);
		}
	}

	Gtk.ContentFit _content_fit = Gtk.ContentFit.CONTAIN;
	public Gtk.ContentFit content_fit {
		get { return _content_fit; }
		set {
			if (_content_fit == value) return;

			_content_fit = value;
			this.queue_draw ();
		}
	}

	bool _can_shrink = true;
	public bool can_shrink {
		get { return _can_shrink; }
		set {
			if (_can_shrink == value) return;

			_can_shrink = value;
			this.queue_resize ();
		}
	}

	Gdk.Paintable? _paintable = null;
	public Gdk.Paintable? paintable {
		get { return _paintable; }
		set {
			if (_paintable == value) return;
			clear_paintable ();

			_paintable = value;
			if (_paintable != null) {
				Gdk.PaintableFlags flags = _paintable.get_flags ();
				if (!(Gdk.PaintableFlags.STATIC_CONTENTS in flags))
					paintable_invalidate_contents_signal = _paintable.invalidate_contents.connect (paintable_invalidate_contents);

				if (!(Gdk.PaintableFlags.STATIC_SIZE in flags))
					paintable_invalidate_size_signal = _paintable.invalidate_size.connect (paintable_invalidate_size);
			}

			this.queue_resize ();
		}
	}

	static construct {
		set_css_name ("picture");
	 }

	construct {
		this.set_accessible_role (Gtk.AccessibleRole.IMG);
		this.overflow = Gtk.Overflow.HIDDEN;
	}

	public FocusPicture.for_paintable (Gdk.Paintable? t_paintable) {
		if (t_paintable == null) return;
		this.paintable = t_paintable;
	}

	public override Gtk.SizeRequestMode get_request_mode () {
		return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (_paintable == null) return;

		int width = this.get_width ();
		int height = this.get_height ();
		double ratio = _paintable.get_intrinsic_aspect_ratio ();

		if (_content_fit == Gtk.ContentFit.FILL || ratio == 0) {
			_paintable.snapshot (snapshot, width, height);
		} else {
			double w = 0.0;
			double h = 0.0;
			double picture_ratio = (double) width / height;
			int paintable_width = _paintable.get_intrinsic_width ();
			int paintable_height = _paintable.get_intrinsic_height ();

			if (
				_content_fit == Gtk.ContentFit.SCALE_DOWN
				&& width >= paintable_width
				&& height >= paintable_height
			) {
				w = paintable_width;
				h = paintable_height;
			} else if (ratio > picture_ratio) {
				if (_content_fit == Gtk.ContentFit.COVER) {
					w = height * ratio;
					h = height;
				} else {
					w = width;
					h = width / ratio;
				}
			} else {
				if (_content_fit == Gtk.ContentFit.COVER) {
					w = width;
					h = width / ratio;
				} else {
					w = height * ratio;
					h = height;
				}
			}

			w = Math.ceil (w);
			h = Math.ceil (h);

			double x = (width - w) / 2;
			double y = Math.floor (height - h) / 2;

			if (_content_fit == Gtk.ContentFit.COVER) {
				x = x + x * focus_x;
				y = y + y * focus_y;
			}

			snapshot.save ();
			snapshot.translate (Graphene.Point () { x = (float) x, y = (float) y });
			_paintable.snapshot (snapshot, w, h);
			snapshot.restore ();
		}
	}

	public override void measure (
		Gtk.Orientation orientation,
		int for_size,
		out int minimum,
		out int natural,
		out int minimum_baseline,
		out int natural_baseline
	) {
		minimum_baseline = -1;
		natural_baseline = -1;

		if (_paintable == null || for_size == 0) {
			minimum = 0;
			natural = 0;
			return;
		}

		double min_width = 0.0;
		double min_height = 0.0;
		double nat_width = 0.0;
		double nat_height = 0.0;
		double default_size = 1.0;

		if (!_can_shrink) {
			_paintable.compute_concrete_size (
				0,
				0,
				default_size,
				default_size,
				out min_width,
				out min_height
			);
		}

		if (orientation == Gtk.Orientation.HORIZONTAL) {
			_paintable.compute_concrete_size (
				0,
				for_size < 0 ? 0 : for_size,
				default_size,
				default_size,
				out nat_width,
				out nat_height
			);

			minimum = (int) Math.ceil (min_width);
			natural = (int) Math.ceil (nat_width);
		} else {
			_paintable.compute_concrete_size (
				for_size < 0 ? 0 : for_size,
				0,
				default_size,
				default_size,
				out nat_width,
				out nat_height
			);

			minimum = (int) Math.ceil (min_height);
			natural = (int) Math.ceil (nat_height);
		}
	}

	private void paintable_invalidate_contents () {
		this.queue_draw ();
	}

	private void paintable_invalidate_size () {
		this.queue_resize ();
	}

	private void clear_paintable () {
		if (_paintable == null) return;

		if (paintable_invalidate_contents_signal != 0) _paintable.disconnect (paintable_invalidate_contents_signal);
		if (paintable_invalidate_size_signal != 0) _paintable.disconnect (paintable_invalidate_size_signal);

		paintable_invalidate_contents_signal = 0;
		paintable_invalidate_size_signal = 0;

		_paintable = null;
	}

	~FocusPicture () {
		clear_paintable ();
	}
}
