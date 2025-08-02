public interface Tuba.Dialogs.Composer.PreferredSizeable : GLib.Object {
	public abstract int preferred_height { get; set; default = -1; }
	public abstract int preferred_width { get; set; default = -1; }
}

public class Tuba.Dialogs.Composer.PreferredSizeBin : Gtk.Widget {
	private int _height = -1;
	public int height {
		get { return _height; }
		set {
			_height = value;
			this.queue_resize ();
		}
	}

	private int _width = -1;
	public int width {
		get { return _width; }
		set {
			_width = value;
			this.queue_resize ();
		}
	}

	~PreferredSizeBin () {
		debug ("Destroying PreferredSizeBin");
	}

	public override void dispose () {
		if (this.child != null) {
			this.child.unparent ();
			this.child = null;
		}

		base.dispose ();
	}

	static construct {
		set_accessible_role (Gtk.AccessibleRole.GENERIC);
	}

	private Gtk.Widget? _child = null;
	public Gtk.Widget? child {
		get { return _child; }
		set {
			if (_child != null) {
				_child.unparent ();
			}

			_child = value;
			if (_child != null) _child.set_parent (this);
		}
	}

	public override Gtk.SizeRequestMode get_request_mode () {
		if (this.child != null) return this.child.get_request_mode ();
		return Gtk.SizeRequestMode.CONSTANT_SIZE;
	}

	public override void measure (
		Gtk.Orientation orientation,
		int for_size,
		out int minimum,
		out int natural,
		out int minimum_baseline,
		out int natural_baseline
	) {
		if (this.child == null) {
			minimum_baseline = natural_baseline = -1;
			minimum = natural = 0;
			return;
		}

		child.measure (
			orientation,
			for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);

		if (this.width != -1 || this.height != -1) {
			natural = int.max (minimum, int.max (natural, orientation == HORIZONTAL ? this.width : this.height));
		}
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (this.child == null) {
			base.snapshot (snapshot);
			return;
		}

		this.snapshot_child (this.child, snapshot);
	}

	public override void size_allocate (int width, int height, int baseline) {
		if (this.child == null) {
			base.size_allocate (width, height, baseline);
			return;
		}

		this.child.allocate (width, height, baseline, null);
	}
}
