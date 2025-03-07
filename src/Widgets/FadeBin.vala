public class Tuba.Widgets.FadeBin : Gtk.Widget {
	const int MAX_HEIGHT = 300;
	const float FADE_HEIGHT = 125f;

	private Gtk.Widget? _child = null;
	public Gtk.Widget? child {
		get { return _child; }
		set {
			if (_child != null) _child.unparent ();
			_child = value;
			_child.set_parent (this);
		}
	}

	~FadeBin () {
		if (this.child != null) this.child.unparent ();
	}

	public override Gtk.SizeRequestMode get_request_mode () {
		if (this.child != null) return this.child.get_request_mode ();
		return Gtk.SizeRequestMode.HEIGHT_FOR_WIDTH;
	}

	private bool _reveal = false;
	public bool reveal {
		get { return _reveal; }
		set {
			if (_reveal != value) {
				_reveal = value;
				this.queue_draw ();
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
			base.size_allocate (width, height, baseline);
			this.should_fade = false;
			return;
		}

		this.child.allocate (width, height, baseline, null);
		if (this.reveal) {
			this.should_fade = false;
			return;
		}

		this.should_fade = this.child.get_height () >= MAX_HEIGHT;
	}

	public override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
		this.child.measure (
			orientation,
			for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);
		if (this.reveal) return;

		minimum = int.min (minimum, MAX_HEIGHT);
		minimum_baseline = -1;
		natural_baseline = -1;
		if (orientation == Gtk.Orientation.VERTICAL) {
			natural = MAX_HEIGHT;
		}
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (this.child == null || !this.faded) {
			this.child.snapshot (snapshot);
			return;
		}

		var height = this.get_height ();
		if (height <= 0) {
			this.child.snapshot (snapshot);
			return;
		}

		Gtk.Snapshot child_snapshot = new Gtk.Snapshot ();
		this.snapshot_child (this.child, child_snapshot);
		var node = child_snapshot.to_node ();
		if (node == null) {
			this.child.snapshot (snapshot);
			return;
		}

		var bounds = node.get_bounds ();
		bounds.origin.y = 0;
		bounds.origin.x = Math.floorf (bounds.origin.x);
		bounds.size.width = Math.ceilf (bounds.size.width) + 1;
		bounds.size.height = height;

		snapshot.push_mask (Gsk.MaskMode.INVERTED_ALPHA);

		var new_fade = height - FADE_HEIGHT;
		snapshot.append_linear_gradient (
			Graphene.Rect () {
				origin = Graphene.Point () {
					x = bounds.origin.x,
					y = new_fade
				},
				size = Graphene.Size () {
					width = bounds.size.width,
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
		snapshot.push_clip (bounds);
		snapshot.append_node (node);
		snapshot.pop ();
		snapshot.pop ();
	}
}
