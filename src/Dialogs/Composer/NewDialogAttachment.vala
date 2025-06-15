public class Tuba.Dialogs.Components.Attachment : Adw.Bin {
	public signal void switch_place (Attachment with);

	public class AltIndicator : Gtk.Box {
		private bool _valid = false;
		public bool valid {
			get { return _valid; }
			set {
				_valid = value;
				update_valid ();
			}
		}

		static construct {
			set_accessible_role (Gtk.AccessibleRole.PRESENTATION);
		}

		Gtk.Image icon;
		construct {
			this.orientation = HORIZONTAL;
			this.spacing = 3;
			this.can_focus = this.focusable = false;
			this.css_classes = { "alt-indicator" };
			icon = new Gtk.Image.from_icon_name ("tuba-cross-large-symbolic");

			this.append (new Gtk.Label ("ALT"));
			this.append (icon);

			update_valid ();
		}

		private void update_valid () {
			if (this.valid) {
				if (this.has_css_class ("error")) this.remove_css_class ("error");
				if (!this.has_css_class ("success")) this.add_css_class ("success");
				icon.icon_name = "tuba-check-plain-symbolic";
			} else {
				if (!this.has_css_class ("error")) this.add_css_class ("error");
				if (this.has_css_class ("success")) this.remove_css_class ("success");
				icon.icon_name = "tuba-cross-large-symbolic";
			}
		}
	}

	public Gdk.Paintable paintable {
		get { return picture.paintable; }
		set {
			picture.paintable = value;
		}
	}

	Adw.TimedAnimation opacity_animation;
	Widgets.FocusPicture picture;
	Gtk.Button delete_button;
	Gtk.Button alt_button;
	Gtk.Box alt_indicator;
	construct {
		this.css_classes = { "composer-attachment" };

		var overlay = new Gtk.Overlay () {
			vexpand = true,
			hexpand = true
		};

		picture = new Widgets.FocusPicture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			content_fit = Gtk.ContentFit.COVER
		};

		delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			halign = END,
			valign = START,
			margin_top = 6,
			margin_end = 6,
			css_classes = { "osd", "circular" }
		};

		// TODO: combine alt editor and focus picker
		alt_button = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
			halign = END,
			valign = END,
			margin_bottom = 6,
			margin_end = 6,
			css_classes = { "osd", "circular" }
		};

		alt_indicator = new AltIndicator () {
			halign = START,
			valign = END,
			margin_bottom = 6,
			margin_start = 6
		};

		overlay.add_overlay (delete_button);
		overlay.add_overlay (alt_button);
		overlay.add_overlay (alt_indicator);

		this.child = overlay;
		this.height_request = 120;

		var drag_source_controller = new Gtk.DragSource () {
			actions = MOVE
		};
		drag_source_controller.prepare.connect (on_drag_prepare);
		drag_source_controller.drag_begin.connect (on_drag_begin);
		drag_source_controller.drag_end.connect (on_drag_end);
		drag_source_controller.drag_cancel.connect (on_drag_cancel);
		this.add_controller (drag_source_controller);

		var drop_target_controller = new Gtk.DropTarget (typeof (Attachment), MOVE);
		drop_target_controller.drop.connect (on_drop);
		this.add_controller (drop_target_controller);

		opacity_animation = new Adw.TimedAnimation (this, 0, 1, 200, new Adw.PropertyAnimationTarget (this, "opacity")) {
			easing = Adw.Easing.LINEAR
		};
	}

	public Attachment.from_paintable (Gdk.Paintable? paintable) {
		picture.paintable = paintable;
	}

	double drag_x = 0;
	double drag_y = 0;
	private Gdk.ContentProvider? on_drag_prepare (double x, double y) {
		drag_x = x;
		drag_y = y;

		Value value = Value (typeof (Attachment));
		value.set_object (this);

		return new Gdk.ContentProvider.for_value (value);
	}

	private void on_drag_begin (Gtk.DragSource ds_controller, Gdk.Drag drag) {
		ds_controller.set_icon ((new Gtk.WidgetPaintable (this)).get_current_image (), (int) drag_x, (int) drag_y);

		animate_opacity (true);
	}

	private void on_drag_end (Gdk.Drag drag, bool delete_data) {
		animate_opacity ();
	}

	private bool on_drag_cancel (Gdk.Drag drag, Gdk.DragCancelReason reason) {
		animate_opacity ();
		return false;
	}

	private bool on_drop (Gtk.DropTarget dt_controller, GLib.Value value, double x, double y) {
		if (dt_controller.get_value () == null || dt_controller.get_value ().get_object () == this) return false;
		switch_place (dt_controller.get_value ().get_object () as Attachment);
		return true;
	}

	private void animate_opacity (bool hide = false) {
		if (opacity_animation.state == PLAYING) opacity_animation.pause ();

		opacity_animation.value_from = opacity_animation.value;
		opacity_animation.value_to = hide ? 0 : 1;
		opacity_animation.play ();
	}
}
