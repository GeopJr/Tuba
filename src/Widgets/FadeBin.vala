public class Tuba.Widgets.FadeBin : Gtk.Widget {
	const int MAX_HEIGHT = 300;
	const float FADE_HEIGHT = 125f;
	const uint ANIMATION_DURATION = 300;

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

	public void reveal_animated () {
		animation.value_from = 0.0;
		animation.value_to = 1.0;
		animation.play ();
	}

	public void hide_animated () {
		animation.value_from = 1.0;
		animation.value_to = 0.0;
		animation.play ();
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
		{ 0f, { 1, 1, 1, 1f } },
		{ 1f, { 0, 0, 0, 0f } },
	};

	Adw.TimedAnimation animation;
	construct {
		var target = new Adw.CallbackAnimationTarget (animation_target_cb);
		animation = new Adw.TimedAnimation (this, 0.0, 1.0, ANIMATION_DURATION, target) {
			easing = Adw.Easing.EASE_IN_OUT_QUART
		};
		animation.done.connect (on_animation_end);
	}

	private void on_animation_end () {
		this.reveal = !this.reveal;
	}

	private void animation_target_cb (double value) {
		this.queue_resize ();
	}

	private inline double lerp (int a, int b, double p) {
		return a * (1.0 - p) + b * p;
	}

	private inline double inverse_lerp (int a, int r, double p) {
		return (r - a * (1.0 - p)) / p;
	}

	public override void size_allocate (int width, int height, int baseline) {
		if (this.child == null) {
			this.should_fade = false;
			return;
		}

		int child_min_height;
		this.child.measure (Gtk.Orientation.VERTICAL, width, out child_min_height, null, null, null);
		var child_height = int.max (height, child_min_height);
		this.child.allocate (width, child_height, baseline, null);

		this.should_fade = !this.reveal && child_height >= MAX_HEIGHT;
	}

	public override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
		if (this.child == null) {
			minimum_baseline = natural_baseline = -1;
			minimum = natural = 0;
			return;
		}

		int child_for_size;
		if (this.reveal || orientation == Gtk.Orientation.VERTICAL || for_size < MAX_HEIGHT || for_size == -1) {
			child_for_size = for_size;
		} else if (this.animation.value == 0.0) {
			child_for_size = -1;
		} else {
			child_for_size = (int) Math.floor (inverse_lerp (
				MAX_HEIGHT,
				for_size,
				this.animation.value
			));
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
			minimum_baseline = natural_baseline = -1;

			if (minimum > MAX_HEIGHT) {
				minimum = (int) Math.ceil (lerp (
					MAX_HEIGHT,
					minimum,
					this.animation.value
				));
			}

			if (natural > MAX_HEIGHT) {
				natural = (int) Math.ceil (lerp (
					MAX_HEIGHT,
					natural,
					this.animation.value
				));
			}
		}
	}

	const float LOTS = 1000f;
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
		var width = this.get_width ();

		Graphene.Rect clip_rect = Graphene.Rect () {
			origin = Graphene.Point () {
				x = -LOTS,
				y = -LOTS
			},
			size = Graphene.Size () {
				width = width + 2 * LOTS,
				height = height + LOTS
			}
		};
		snapshot.push_clip (clip_rect);

		snapshot.push_mask (Gsk.MaskMode.ALPHA);
		snapshot.append_linear_gradient (
			clip_rect,
			Graphene.Point () {
				x = 0,
				y = height - FADE_HEIGHT
			},
			Graphene.Point () {
				x = 0,
				y = height
			},
			GRADIENT
		);
		snapshot.pop ();

		this.snapshot_child (this.child, snapshot);
		snapshot.pop ();
		snapshot.pop ();
	}
}
