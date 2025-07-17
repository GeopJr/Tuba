// The focuspoint picker
// The API is a bit strange as it's based on https://github.com/jonom/jquery-focuspoint#1-calculate-your-images-focus-point
// In summary, they are coordinates, where (1,1) is the top-right corner of the image
// and (-1,-1) is the bottom-left one
// This widget is responsible not only for picking the position on top of the image,
// but also converting the position between the API coordinates and the width-height GTK ones
public class Tuba.Widgets.FocusPicker : Gtk.Widget {
	Gtk.Picture pic;
	Gtk.Fixed fixed;
	Gtk.Image picker;
	Gtk.AspectFrame frame;
	Gtk.Overlay overlay;

	private double _pos_x = 0.0;
	public double pos_x {
		get { return _pos_x; }
		set {
			_pos_x = value;

			update_dot_pos ();
		}
	}

	private double _pos_y = 0.0;
	public double pos_y {
		get { return _pos_y; }
		set {
			_pos_y = value;

			update_dot_pos ();
		}
	}

	double picker_width_half = 0;
	double picker_height_half = 0;

	construct {
		overlay = new Gtk.Overlay () {
			vexpand = true,
			hexpand = true
		};

		picker = new Gtk.Image.from_icon_name ("tuba-radio-checked-symbolic") {
			css_classes = { "osd", "focus-picker" },
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			icon_size = Gtk.IconSize.LARGE,
			// translators: focus picking knob(?)/target(?) tooltip in the focus picker
			tooltip_text = _("Focus Picker")
		};

		fixed = new Gtk.Fixed ();
		overlay.add_overlay (fixed);
		overlay.set_clip_overlay (fixed, true);

		var picker_click_gesture = new Gtk.GestureClick () {
			button = Gdk.BUTTON_PRIMARY,
			propagation_phase = Gtk.PropagationPhase.CAPTURE
		};
		picker_click_gesture.pressed.connect (on_pointer_click);
		picker_click_gesture.released.connect (on_pointer_click_release);
		picker.add_controller (picker_click_gesture);

		var fixed_click_gesture = new Gtk.GestureClick () {
			button = Gdk.BUTTON_PRIMARY,
			propagation_phase = Gtk.PropagationPhase.CAPTURE
		};
		fixed_click_gesture.pressed.connect (on_fixed_click);
		fixed.add_controller (fixed_click_gesture);

		var motion = new Gtk.EventControllerMotion ();
		motion.motion.connect (on_motion);
		fixed.add_controller (motion);
	}

	private void on_fixed_click (int n_press, double x, double y) {
		if (dragging) return;

		on_motion_real (x, y);
	}

	// When the picker is clicked,
	// initialize dragging
	bool dragging = false;
	private void on_pointer_click () {
		dragging = true;
	}

	// When the picker is released,
	// stop dragging
	private void on_pointer_click_release () {
		dragging = false;
	}

	// When the cursor is moving in the fixed widget,
	// check if the picker is being dragged and if so,
	// move it to the new position
	private void on_motion (double x, double y) {
		if (!dragging) return;

		on_motion_real (x, y);
	}

	// Calculate the new the focuspoint the API accepts
	// Width, Height position => API position
	private void on_motion_real (double x, double y) {
		x = x.clamp (0, pic.get_width ());
		y = y.clamp (0, pic.get_height ());

		pos_x = (((2 * x) / pic.get_width ()) - 1);
		pos_y = (((2 * y) / pic.get_height ()) - 1) * -1;
	}

	public FocusPicker (Gdk.Paintable paintable) {
		pic = new Gtk.Picture.for_paintable (paintable);
		overlay.child = pic;

		frame = new Gtk.AspectFrame (
			0.5f,
			0.5f,
			(float) pic.paintable.get_intrinsic_aspect_ratio (),
			false
		) {
			child = overlay
		};
		frame.set_parent (this);

		// Center the picker
		fixed.put (picker, pic.get_width () / 2, pic.get_height () / 2);
	}

	public override void size_allocate (int width, int height, int baseline) {
		frame.allocate (width, height, baseline, null);

		// Calculate these here once as they're static
		if (picker_width_half == 0 || picker_height_half == 0) compute_picker_half ();

		update_dot_pos ();
	}

	public override void measure (
		Gtk.Orientation orientation,
		int for_size,
		out int minimum,
		out int natural,
		out int minimum_baseline,
		out int natural_baseline
	) {
		this.frame.measure (
			orientation,
			for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		base.snapshot (snapshot);
	}

	// Moves the picker to the new positions based on
	// the focuspoint the API accepts
	// API position => Width, Height position
	// minus the picker transformations
	private void update_dot_pos () {
		var new_x = pic.get_width () / 2;
		var new_y = pic.get_height () / 2;

		fixed.move (
			picker,
			(new_x + new_x * pos_x) - picker_width_half,
			(new_y + new_y * pos_y * -1) - picker_height_half
		);
	}

	private void compute_picker_half () {
		Graphene.Rect rect;
		if (!picker.compute_bounds (fixed, out rect)) {
			picker_width_half = picker.get_width () / 2;
			picker_height_half = picker.get_height () / 2;
		} else {
			picker_width_half = rect.size.width / 2;
			picker_height_half = rect.size.height / 2;
		}
	}

	~FocusPicker () {
		debug ("Destroying FocusPicker");
		frame.unparent ();
	}
}
