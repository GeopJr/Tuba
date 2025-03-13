public class Tuba.Widgets.FadeBin : Gtk.Widget {
	const int MAX_HEIGHT = 300;
	const float FADE_HEIGHT = 125f;

	private unowned Gtk.Widget? _child = null;
	public Gtk.Widget? child {
		get { return _child; }
		set {
			if (_child != null) _child.unparent ();
			_child = value;
			if (_child != null) _child.set_parent (this);
		}
	}

	public override void dispose () {
		if (this.child != null) {
			this.child.unparent ();
			this.child = null;
		}

		base.dispose ();
	}

	public override Gtk.SizeRequestMode get_request_mode () {
		if (this.child != null) return this.child.get_request_mode ();
		return Gtk.SizeRequestMode.CONSTANT_SIZE;
	}

	private bool _reveal = false;
	public bool reveal {
		get { return _reveal; }
		set {
			if (_reveal != value) {
				_reveal = value;
				this.queue_resize ();
			}
		}
	}

	private bool _should_fade = false;
	private bool should_fade {
		get { return _should_fade; }
		set {
			if (_should_fade != value) {
				_should_fade = value;
				this.notify_property ("faded");
			}
		}
	}

	public bool faded {
		get {
			return this.should_fade && !reveal;
		}
	}

	const Gsk.ColorStop[] GRADIENT = {
		{ 0f, { 0, 0, 0, 1f } },
		{ 1f, { 0, 0, 0, 0f } },
	};

	public override void size_allocate (int width, int height, int baseline) {
		if (this.child == null) {
			this.should_fade = false;
			return;
		}

		int child_min_height;
		this.child.measure (Gtk.Orientation.VERTICAL, width, out child_min_height, null, null, null);
		var child_height = int.max (height, child_min_height);
		this.child.allocate (width, child_height, baseline, null);
		if (this.reveal) {
			this.should_fade = false;
			return;
		}

		this.should_fade = child_height >= MAX_HEIGHT;
	}

	public override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
		if (this.child == null) {
			base.measure (orientation, for_size, out minimum, out natural, out minimum_baseline, out natural_baseline);
			return;
		}

		int child_for_size;
		if (this.reveal || orientation == Gtk.Orientation.VERTICAL || for_size < MAX_HEIGHT) {
			child_for_size = for_size;
		} else {
			child_for_size = -1;
		}

		this.child.measure (
			orientation,
			child_for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);

		if (orientation == Gtk.Orientation.VERTICAL && !this.reveal) {
			minimum = int.min (minimum, MAX_HEIGHT);
			natural = int.min (natural, MAX_HEIGHT);
		}
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (this.child == null) {
			base.snapshot (snapshot);
			return;
		}

		if (!this.faded) {
			this.snapshot_child (this.child, snapshot);
			return;
		}

		var height = this.get_height ();
		if (height <= 0) {
			this.snapshot_child (this.child, snapshot);
			return;
		}
		var width = this.get_width ();
		var new_fade = height - FADE_HEIGHT;

		snapshot.push_mask (Gsk.MaskMode.INVERTED_ALPHA);
		snapshot.append_linear_gradient (
			Graphene.Rect () {
				origin = Graphene.Point () {
					x = 0,
					y = new_fade
				},
				size = Graphene.Size () {
					width = width,
					height = FADE_HEIGHT
				}
			},
			Graphene.Point () {
				x = 0,
				y = height
			},
			Graphene.Point () {
				x = 0,
				y = new_fade
			},
			GRADIENT
		);

		snapshot.pop ();
		snapshot.push_clip (Graphene.Rect () {
			origin = Graphene.Point () {
				x = 0,
				y = 0
			},
			size = Graphene.Size () {
				width = width,
				height = height
			}
		});
		this.snapshot_child (this.child, snapshot);
		snapshot.pop ();
		snapshot.pop ();
	}
}
