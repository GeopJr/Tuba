// ScaleRevealer is ported from Fractal
// https://gitlab.gnome.org/GNOME/fractal/-/blob/e1976cd4e182cc8513d52c1a985a4fce9a056ad2/src/components/scale_revealer.rs

public class Tuba.Widgets.ScaleRevealer : Adw.Bin {
	const uint ANIMATION_DURATION = 300;

	public signal void transition_done ();
	public Adw.TimedAnimation animation { get; construct set; }
	private Gtk.Widget? _source_widget = null;
	public Gtk.Widget? source_widget {
		get {
			return _source_widget;
		}
		set {
			if (_source_widget != null)
				_source_widget.opacity = 1.0;
			_source_widget = value;
			update_source_widget ();
		}
	}
	public Gdk.Texture? source_widget_texture { get; set; }

	private void update_source_widget () {
		if (this.source_widget == null) {
			source_widget_texture = null;
		} else {
			var t_source_widget_texture = render_widget_to_texture (this.source_widget);
			if (t_source_widget_texture != null)
				source_widget_texture = t_source_widget_texture;
			this.source_widget.opacity = 0.0;
		}
	}

	private bool _reveal_child = false;
	public bool reveal_child {
		get {
			return _reveal_child;
		}

		set {
			if (_reveal_child == value) return;
			animation.value_from = animation.value;

			if (value) {
				animation.value_to = 1.0;
				this.visible = true;
				update_source_widget ();
			} else {
				animation.value_to = 0.0;
			}

			_reveal_child = value;
			animation.play ();
			this.notify_property ("reveal-child");
		}
	}

	private Gdk.Texture? render_widget_to_texture (Gtk.Widget widget) {
		var widget_paintable = new Gtk.WidgetPaintable (widget);
		var t_snapshot = new Gtk.Snapshot ();

		widget_paintable.snapshot (
			t_snapshot,
			widget_paintable.get_intrinsic_width (),
			widget_paintable.get_intrinsic_height ()
		);

		var node = t_snapshot.to_node ();
		var native = widget.get_native ();
		if (native == null || node == null) return null;

		return native.get_renderer ().render_texture (node, null);
	}

	construct {
		var target = new Adw.CallbackAnimationTarget (animation_target_cb);
		animation = new Adw.TimedAnimation (this, 0.0, 1.0, ANIMATION_DURATION, target) {
			easing = Adw.Easing.EASE_IN_OUT_QUART
		};
		animation.done.connect (on_animation_end);

		this.visible = false;
	}

	private void on_animation_end () {
		if (!reveal_child) {
			if (source_widget != null)
				source_widget.opacity = 1.0;
			this.visible = false;
		}

		transition_done ();
	}

	private void animation_target_cb (double value) {
		this.queue_draw ();
	}

	const Graphene.Rect FALLBACK_BOUNDS = {
		{ 0.0f, 0.0f },
		{ 100.0f, 100.0f }
	};

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (this.child == null) return;

		var progress = this.animation.value;
		if (progress == 1.0) {
			this.snapshot_child (this.child, snapshot);
			return;
		}
		var rev_progress = (1.0 - progress).abs ();

		// Vala will complain about possibly unassigned local variable
		// if source_bounds doesn't have a default value
		Graphene.Rect source_bounds = FALLBACK_BOUNDS;

		// let's avoid reassigning source_bounds by splitting it into
		// two if statements
		if (this.source_widget != null) {
			if (!this.source_widget.compute_bounds (this, out source_bounds)) source_bounds = FALLBACK_BOUNDS;
		}

		float x_scale = source_bounds.get_width () / this.get_width ();
		float y_scale = source_bounds.get_height () / this.get_height ();

		x_scale = 1.0f + (x_scale - 1.0f) * (float) rev_progress;
		y_scale = 1.0f + (y_scale - 1.0f) * (float) rev_progress;

		float x = source_bounds.get_x () * (float) rev_progress;
		float y = source_bounds.get_y () * (float) rev_progress;

		snapshot.translate (Graphene.Point () { x = x, y = y });
		snapshot.scale (x_scale, y_scale);

		if (source_widget == null) return;
		if (source_widget_texture == null) {
			warning ("The source widget texture is None, using child snapshot as fallback");
			this.snapshot_child (this.child, snapshot);
		} else {
			if (progress > 0.0) {
				if (progress > 0.3) {
					this.snapshot_child (this.child, snapshot);
					return;
				}

				snapshot.push_cross_fade (progress);
				source_widget_texture.snapshot (
					snapshot,
					this.get_width (),
					this.get_height ()
				);
				snapshot.pop ();

				this.snapshot_child (this.child, snapshot);
				snapshot.pop ();
			} else if (progress <= 0.0) {
				source_widget_texture.snapshot (
					snapshot,
					this.get_width (),
					this.get_height ()
				);
			}
		}
	}
}
