public class Tuba.Widgets.ScaleRevealer : Adw.Bin {
	const uint ANIMATION_DURATION = 250;

	public signal void transition_done ();
	public Adw.TimedAnimation animation { get; construct set; }
	public Gtk.Widget? source_widget { get; set; }
	public Gdk.Texture? source_widget_texture { get; set; }

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

				if (source_widget == null) {
					source_widget_texture = null;
				} else {
					source_widget_texture = render_widget_to_texture (this.source_widget);
					source_widget.opacity = 0.0;
				}
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
			easing = Adw.Easing.EASE_OUT_QUART
		};
		animation.done.connect (on_animation_end);

		this.visible = false;
	}

	private void on_animation_end () {
		if (!reveal_child) {
			source_widget.opacity = 1.0;
			this.visible = false;
		}

		transition_done ();
	}

	private void animation_target_cb (double value) {
		this.queue_draw ();
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (this.child == null) return;

		var progress = this.animation.value;
		if (progress == 1.0) {
			this.snapshot_child (this.child, snapshot);
			return;
		}
		var rev_progress = (1.0 - progress).abs ();

		Graphene.Rect source_bounds;
		if (!this.source_widget.compute_bounds (this, out source_bounds)) source_bounds = Graphene.Rect () {
			origin = Graphene.Point () { x = 0.0f, y = 0.0f },
			size = Graphene.Size () { width = 100.0f, height = 100.0f }
		};

		float x_scale = source_bounds.get_width () / this.get_width ();
		float y_scale = source_bounds.get_height () / this.get_height ();

		x_scale = 1.0f + (x_scale - 1.0f) * (float) rev_progress;
		y_scale = 1.0f + (y_scale - 1.0f) * (float) rev_progress;

		float x = source_bounds.get_x () * (float) rev_progress;
		float y = source_bounds.get_y () * (float) rev_progress;

		snapshot.translate (Graphene.Point () { x = x, y = y });
		snapshot.scale (x_scale, y_scale);

		if (source_widget_texture == null) {
			warning ("The source widget texture is None, using child snapshot as fallback");
			this.snapshot_child (this.child, snapshot);
		} else {
			if (progress > 0.0) {
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
