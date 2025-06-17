public class Tuba.Widgets.SandwichSourceView : GtkSource.View {
	Gtk.Widget? top_child = null;
	Gtk.Widget? bottom_child = null;
	Adw.TimedAnimation scroll_animation;
	~SandwichSourceView () {
		debug ("Destroying SandwichSourceView");
	}

	// Vala hasn't had a release with the 4.18 VAPI yet.
	#if !VALAC_05619
		[CCode (cheader_filename = "gtk/gtk.h", cname = "gtk_text_view_get_visible_offset")]
		extern void get_visible_offset (out double x_offset, out double y_offset);
	#endif

	public override void dispose () {
		add_top_child (null);
		add_bottom_child (null);

		base.dispose ();
	}

	construct {
		this.accepts_tab = false;
		this.wrap_mode = Gtk.WrapMode.WORD_CHAR;

		this.map.connect (on_map);
		// We need to focus out of the child widgets
		// when the cursor is actually in use
		this.move_cursor.connect (focus_on_view);
		this.buffer.changed.connect (focus_on_view);
	}

	private void focus_on_view () {
		if (!this.has_focus) this.grab_focus ();
	}

	public virtual void add_top_child (Gtk.Widget? new_top_child) {
		if (new_top_child == null) {
			if (this.top_child != null) {
				this.top_child.unparent ();
				this.top_child = null;
			}
			return;
		}

		if (this.top_child != null) this.top_child.unparent ();
		this.top_child = new_top_child;

		var focus_controller = new Gtk.EventControllerFocus ();
		focus_controller.enter.connect (scroll_to_top_widget);
		focus_controller.leave.connect (on_focus_leave);
		this.top_child.add_controller (focus_controller);

		setup_child_widget (this.top_child);
	}

	public virtual void add_bottom_child (Gtk.Widget? new_bottom_child) {
		if (new_bottom_child == null) {
			if (this.bottom_child != null) {
				this.bottom_child.unparent ();
				this.bottom_child = null;
			}
			return;
		}

		if (this.bottom_child != null) this.bottom_child.unparent ();
		this.bottom_child = new_bottom_child;

		var focus_controller = new Gtk.EventControllerFocus ();
		focus_controller.enter.connect (scroll_to_bottom_widget);
		focus_controller.leave.connect (on_focus_leave);
		this.bottom_child.add_controller (focus_controller);

		setup_child_widget (this.bottom_child);
	}

	private void scroll_to_top_widget () {
		scroll_to_widget (false);
		this.editable = false;
	}

	private void scroll_to_bottom_widget () {
		scroll_to_widget (true);
		this.editable = false;
	}

	private void on_focus_leave () {
		this.editable = true;
	}

	private inline void setup_child_widget (Gtk.Widget wdgt) {
		wdgt.set_parent (this);
		wdgt.set_cursor (new Gdk.Cursor.from_name ("default", null));

		Gtk.GestureClick click_gesture = new Gtk.GestureClick () {
			button = 3,
			propagation_phase = BUBBLE
		};
		click_gesture.pressed.connect (on_click_gesture_pressed);
		click_gesture.released.connect (on_click_gesture_pressed);
		wdgt.add_controller (click_gesture);

		this.queue_resize ();
	}

	private void on_click_gesture_pressed (Gtk.GestureClick gesture, int n_press, double x, double y) {
		gesture.set_state (CLAIMED);
	}

	// we need to bind these on map because
	// we don't have the vadjustment at construct
	private void on_map () {
		// we need to bind both because if the value doesn't
		// change but the upper does, the widgets need to be
		// updated
		this.vadjustment.notify["upper"].connect (realloc);
		this.vadjustment.notify["value"].connect (realloc);
		// depends on the vadjustment
		if (scroll_animation != null && scroll_animation.state == PLAYING) scroll_animation.skip ();
		scroll_animation = new Adw.TimedAnimation (this, 0, 1, 500, new Adw.PropertyAnimationTarget (this.vadjustment, "value")) {
			easing = Adw.Easing.EASE_IN_OUT_QUART
		};
	}

	private void realloc () {
		this.queue_allocate ();
	}

	// This is where the widgets look like they stay in place.
	// This is loosely based on how TextView handles overlays.
	//
	// To properly do yoffsets and sizing, we first need to
	// set the top and bottom mergins, then size allocate the
	// textview and then get the yoffset.
	public override void size_allocate (int width, int height, int baseline) {
		// y offset is how far the viewpoint is from the top of the
		// text area. It can be negative when there's a top_margin.
		double yoff = 0;
		int top_child_height = 0;
		int bottom_child_height = 0;

		if (this.top_child != null) {
			this.top_child.measure (VERTICAL, width, out top_child_height, null, null, null);
			if (top_child_height != this.top_margin) this.top_margin = top_child_height;
		} else {
			this.top_margin = 0;
		}

		if (this.bottom_child != null) {
			this.bottom_child.measure (VERTICAL, width, out bottom_child_height, null, null, null);
			if (bottom_child_height != this.bottom_margin) this.bottom_margin = bottom_child_height;
		} else {
			this.bottom_margin = 0;
		}

		base.size_allocate (width, height, baseline);
		this.get_visible_offset (null, out yoff); // NOTE: this only returns a priv variable

		if (this.top_child != null) {
			this.top_child.allocate_size (
				Gtk.Allocation () {
					height = top_child_height,
					width = width,
					x = 0,
					y = (int) (-yoff - top_child_height)
				},
				baseline
			);
		}

		if (this.bottom_child != null) {
			this.bottom_child.allocate_size (
				Gtk.Allocation () {
					height = bottom_child_height,
					width = width,
					x = 0,
					y = (int) (this.vadjustment.upper - yoff - bottom_child_height - this.top_margin)
				},
				baseline
			);
		}
	}

	// The commented out code would set the min/nat values to the biggest ones, but
	// after careful consideration, we really don't need them as the base widget is
	// measured correctly since the other widgets utilize its top_margin and
	// bottom_margin properties
	public override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
		//  minimum = -1;
		//  natural = -1;

		//  if (this.top_child != null) {
		//  	int top_min = -1;
		//  	int top_nat = -1;

		//  	this.top_child.measure (
		//  		orientation,
		//  		for_size,
		//  		out top_min,
		//  		out top_nat,
		//  		null,
		//  		null
		//  	);

		//  	minimum = int.max (minimum, top_min);
		//  	natural = int.max (natural, top_nat);
		//  }

		//  if (this.bottom_child != null) {
		//  	int bottom_min = -1;
		//  	int bottom_nat = -1;

		//  	this.bottom_child.measure (
		//  		orientation,
		//  		for_size,
		//  		out bottom_min,
		//  		out bottom_nat,
		//  		null,
		//  		null
		//  	);

		//  	minimum = int.max (minimum, bottom_min);
		//  	natural = int.max (natural, bottom_nat);
		//  }

		//  int base_min = -1;
		//  int base_nat = -1;
		//  base.measure (orientation, for_size, out base_min, out base_nat, null, null);

		//  minimum = int.max (minimum, base_min);
		//  natural = int.max (natural, base_nat);

		base.measure (orientation, for_size, out minimum, out natural, null, null);
		//  minimum = natural;
		minimum_baseline = natural_baseline = -1;
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		base.snapshot (snapshot);
		if (this.top_child != null) this.snapshot_child (this.top_child, snapshot);
		if (this.bottom_child != null) this.snapshot_child (this.bottom_child, snapshot);
	}

	// Scroll to either the top or bottom widget.
	// We don't have access to the functions Gtk.Viewport
	// uses to calculate and animate the vadjustment changes
	// so this is an in-house implementation.
	protected void scroll_to_widget (bool bottom = false) {
		if (scroll_animation == null) return;
		// We only want to scroll if the widget is not visible
		// which means, for the top one, the value must be bigger
		// than the top_margin,
		// and for the bottom one, it has to be smaller than the
		// upper value - the page size - the bottom_margin,
		// aka the top-most value of the bottom widget.
		double y_val = this.vadjustment.value;
		if (
			(!bottom && y_val < this.top_margin)
			|| (bottom && y_val > (this.vadjustment.upper - this.vadjustment.page_size - this.bottom_margin))
		) return;

		// For animations we use a single TimedAnimation which
		// starts at the current value and animates to the new
		// one which is the top-most for the top widget and
		// the upper value - the bottom_margin for the bottom
		// one - aka if the bottom widget is bigger than a page
		// it will scroll to the point where the top-most part
		// of it will be visible, otherwise it will scroll to
		// the bottom of the scrolledwindow (where the whole
		// widget is visible)
		if (scroll_animation.state == PLAYING) scroll_animation.pause ();

		double scroll_to_value = bottom ? this.vadjustment.upper - this.bottom_margin : 0;
		scroll_animation.value_from = y_val;
		scroll_animation.value_to = scroll_to_value;
		scroll_animation.play ();
	}

	protected void scroll_animated (bool end = false) {
		if (scroll_animation == null) return;
		if (scroll_animation.state == PLAYING) scroll_animation.pause ();
		scroll_animation.value_from = this.vadjustment.value;
		scroll_animation.value_to = end ? this.vadjustment.upper : 0;
		scroll_animation.play ();
	}
}
