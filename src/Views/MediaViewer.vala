// Mostly inspired by Loupe https://gitlab.gnome.org/GNOME/loupe and Fractal https://gitlab.gnome.org/GNOME/fractal

public class Tuba.Attachment {
	public enum MediaType {
        IMAGE,
        VIDEO,
        GIFV,
		AUDIO,
		UNKNOWN;

		public bool can_copy () {
			switch (this) {
				case IMAGE:
					return true;
				default:
					return false;
			}
		}

		public bool is_video () {
			switch (this) {
				case VIDEO:
				case GIFV:
				case AUDIO:
					return true;
				default:
					return false;
			}
		}

        public string to_string () {
			switch (this) {
				case IMAGE:
					return "IMAGE";
				case VIDEO:
					return "VIDEO";
				case GIFV:
					return "GIFV";
				case AUDIO:
					return "AUDIO";
				default:
					return "UNKNOWN";
			}
		}

		public static MediaType from_string (string media_type) {
			string media_type_up = media_type.up ();
			switch (media_type_up) {
				case "IMAGE":
					return IMAGE;
				case "VIDEO":
					return VIDEO;
				case "GIFV":
					return GIFV;
				case "AUDIO":
					return AUDIO;
				default:
					return UNKNOWN;
			}
		}
    }
}

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/media_viewer.ui")]
public class Tuba.Views.MediaViewer : Gtk.Widget, Gtk.Buildable, Adw.Swipeable {
	const double MAX_ZOOM = 20;
	static double last_used_volume = 1.0;
	const uint CANCEL_SWIPE_ANIMATION_DURATION = 400;

	public class Item : Adw.Bin {
		private Gtk.Stack stack;
		private Gtk.Overlay overlay;
		private Gtk.Spinner spinner;
		private Gtk.ScrolledWindow scroller;
		public signal void zoom_changed ();

		private bool is_done = false;
		public Gtk.Widget child_widget { get; private set; }
		public bool is_video { get; private set; default=false; }
		public string url { get; private set; }
		public double last_x { get; set; default=0.0; }
		public double last_y { get; set; default=0.0; }

		private bool pre_playing = false;
		public bool playing {
			get {
				if (!is_video) return false;
				return is_done ? ((Gtk.Video) child_widget).media_stream.playing : pre_playing;
			}

			set {
				if (!is_video) return;
				if (is_done) {
					((Gtk.Video) child_widget).media_stream.playing = value;
				} else {
					pre_playing = value;
				}
			}
		}

		public bool can_zoom_in {
			get {
				if (is_video) return false;
				return scroller.hadjustment.upper < scroller.hadjustment.page_size * MAX_ZOOM
				&& scroller.vadjustment.upper < scroller.vadjustment.page_size * MAX_ZOOM;
			}
		}

		public bool can_zoom_out {
			get {
				if (is_video) return false;

				// If either horizontal or vertical scrollbar is visible,
				// you should also be able to zoom out
				return scroller.hadjustment.upper > scroller.hadjustment.page_size
						|| scroller.vadjustment.upper > scroller.vadjustment.page_size;
			}
		}

		public int child_width {
			get {
				return child_widget.get_width ();
			}
		}

		public int child_height {
			get {
				return child_widget.get_height ();
			}
		}

		public void update_adjustment (double x, double y) {
			scroller.hadjustment.value = scroller.hadjustment.value - x + last_x;
			scroller.vadjustment.value = scroller.vadjustment.value - y + last_y;
		}

		public void zoom (double zoom_level, int? old_width = null, int? old_height = null) {
			// Don't zoom on video
			if (is_video) return;
			if ((zoom_level > 1.0 && !can_zoom_in) || (zoom_level < 1.0 && !can_zoom_out && settings.media_viewer_expand_pictures) || zoom_level == 1.0) return;

			var new_width = (old_width ?? child_width) * zoom_level;
			var new_height = (old_height ?? child_height) * zoom_level;

			if (settings.media_viewer_expand_pictures) {
				if (new_width < scroller.hadjustment.page_size) new_width = scroller.hadjustment.page_size;
				if (new_height < scroller.vadjustment.page_size) new_height = scroller.vadjustment.page_size;
			} else {
				if (new_width < 0) new_width = -1;
				if (new_height < 0) new_height = -1;
			}

			child_widget.set_size_request ((int) new_width, (int) new_height);

			// Center the viewport
			scroller.vadjustment.upper = new_height;
			scroller.vadjustment.value = (new_height - scroller.vadjustment.page_size) / 2;

			scroller.hadjustment.upper = new_width;
			scroller.hadjustment.value = (new_width - scroller.hadjustment.page_size) / 2;
			emit_zoom_changed ();
		}

		// Stepped zoom
		public void zoom_in () {
			zoom (1.5);
		}

		public void zoom_out () {
			zoom (0.5);
		}

		construct {
			hexpand = true;
			vexpand = true;

			stack = new Gtk.Stack ();
			overlay = new Gtk.Overlay () {
				vexpand = true,
				hexpand = true
			};
			spinner = new Gtk.Spinner () {
				spinning = true,
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
				vexpand = true,
				hexpand = true,
				width_request = 35, // 32 + 3
				height_request = 35,
				css_classes = { "osd", "circular-spinner" }
			};

			overlay.add_overlay (spinner);
			stack.add_named (overlay, "spinner");
			this.child = stack;
		}

		public Item (
			Gtk.Widget child,
			string t_url,
			Gdk.Paintable? paintable,
			bool t_is_video = false
		) {
			this.child_widget = child;
			this.is_video = t_is_video;

			stack.add_named (setup_scrolledwindow (child), "child");
			this.url = t_url;

			if (paintable != null) overlay.child = new Gtk.Picture.for_paintable (paintable);
		}

		~Item () {
			debug ("Destroying MediaViewer.Item");

			if (is_video) {
				last_used_volume = ((Gtk.Video) child_widget).media_stream.muted ? 0.0 : ((Gtk.Video) child_widget).media_stream.volume;
				((Gtk.Video) child_widget).media_stream.stream_unprepared ();
				((Gtk.Video) child_widget).set_file (null);
				((Gtk.Video) child_widget).set_media_stream (null);
			} else {
				((Gtk.Picture) child_widget).paintable = null;
			}

			child_widget.destroy ();
		}

		public void done () {
			if (is_done) return;

			spinner.spinning = false;
			stack.visible_child_name = "child";
			if (is_video) {
				((Gtk.Video) child_widget).media_stream.volume = 1.0 - last_used_volume;
				((Gtk.Video) child_widget).media_stream.volume = last_used_volume;
				((Gtk.Video) child_widget).media_stream.playing = pre_playing;
			};
			is_done = true;
		}

		private Gtk.Widget setup_scrolledwindow (Gtk.Widget child) {
			// Videos shouldn't have a scrolledwindow
			if (is_video) return child;

			scroller = new Gtk.ScrolledWindow () {
				hexpand = true,
				vexpand = true
			};
			scroller.child = child;

			// Emit zoom_changed when the scrolledwindow changes
			scroller.vadjustment.changed.connect (emit_zoom_changed);
			scroller.hadjustment.changed.connect (emit_zoom_changed);

			return scroller;
		}

		public void on_double_click () {
			zoom (can_zoom_out ? -2.5 : 2.5);
		}

		private void emit_zoom_changed () {
			zoom_changed ();
		}
	}

	private bool _fullscreen = false;
	public bool fullscreen {
		set {
			if (value) {
				app.main_window.fullscreen ();
				fullscreen_btn.icon_name = "view-restore-symbolic";
				_fullscreen = true;
			} else {
				app.main_window.unfullscreen ();
				fullscreen_btn.icon_name = "view-fullscreen-symbolic";
				_fullscreen = false;
			}
		}
		get { return app.main_window.fullscreened; }
	}

	private const GLib.ActionEntry[] ACTION_ENTRIES = {
		{"copy-url", copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as", save_as},
	};

	private Gee.ArrayList<Item> items = new Gee.ArrayList<Item> ();
	protected SimpleAction copy_media_simple_action;

	[GtkChild] unowned Gtk.PopoverMenu context_menu;
	[GtkChild] unowned Gtk.Button fullscreen_btn;
	[GtkChild] unowned Adw.HeaderBar headerbar;

	[GtkChild] unowned Gtk.Revealer page_buttons_revealer;
	[GtkChild] unowned Gtk.Button prev_btn;
	[GtkChild] unowned Gtk.Button next_btn;

	[GtkChild] unowned Gtk.Revealer zoom_buttons_revealer;
	[GtkChild] unowned Gtk.Button zoom_out_btn;
	[GtkChild] unowned Gtk.Button zoom_in_btn;

	[GtkChild] unowned Tuba.Widgets.ScaleRevealer scale_revealer;
	[GtkChild] unowned Adw.Carousel carousel;
	[GtkChild] unowned Adw.CarouselIndicatorDots carousel_dots;

	private double swipe_children_opacity {
		set {
			headerbar.opacity =
			carousel_dots.opacity =
			page_buttons_revealer.opacity =
			zoom_buttons_revealer.opacity = value;
		}
	}

	construct {
		// Move between media using the arrow keys
		var keypresscontroller = new Gtk.EventControllerKey ();
		keypresscontroller.key_pressed.connect (on_keypress);
		add_controller (keypresscontroller);

		var drag = new Gtk.GestureDrag ();
		drag.drag_begin.connect (on_drag_begin);
		drag.drag_update.connect (on_drag_update);
		drag.drag_end.connect (on_drag_end);
		add_controller (drag);

		// Pinch to zoom
		var gesture = new Gtk.GestureZoom ();
		gesture.scale_changed.connect (on_scale_changed);
		gesture.end.connect (on_scale_end);
		add_controller (gesture);

		var motion = new Gtk.EventControllerMotion ();
		motion.motion.connect (on_motion);
		add_controller (motion);

		var actions = new GLib.SimpleActionGroup ();
		actions.add_action_entries (ACTION_ENTRIES, this);

		copy_media_simple_action = new SimpleAction ("copy-media", null);
		copy_media_simple_action.activate.connect (copy_media);
		actions.add_action (copy_media_simple_action);

		this.insert_action_group ("mediaviewer", actions);

		this.notify["visible"].connect (on_visible_toggle);
		carousel.notify["n-pages"].connect (on_carousel_n_pages_changed);
		carousel.page_changed.connect (on_carousel_page_changed);
		scale_revealer.transition_done.connect (on_scale_revealer_transition_end);
		context_menu.set_parent (this);

		setup_mouse_previous_click ();
		setup_double_click ();
		setup_mouse_secondary_click ();
		setup_swipe_close ();
	}
	~MediaViewer () {
		debug ("Destroying MediaViewer");
		context_menu.unparent ();
	}

	private void on_visible_toggle () {
		if (this.visible) this.grab_focus ();
	}

	private double swipe_progress { get; set; }
	public Adw.SwipeTracker swipe_tracker;
	private void setup_swipe_close () {
		swipe_tracker = new Adw.SwipeTracker (this) {
			orientation = Gtk.Orientation.VERTICAL,
			enabled = true,
			allow_mouse_drag = true
		};
		swipe_tracker.prepare.connect (on_swipe_tracker_prepare);
		swipe_tracker.update_swipe.connect (on_update_swipe);
		swipe_tracker.end_swipe.connect (on_end_swipe);
	}

	private void on_swipe_tracker_prepare (Adw.NavigationDirection direction) {
		update_revealer_widget ();
	}

	private void on_update_swipe (double progress) {
		this.swipe_children_opacity = 0.0;
		this.swipe_progress = progress;
		this.queue_allocate ();
		this.queue_draw ();
	}

	private void on_end_swipe (double velocity, double to) {
		if (to == 0.0) {
			var target = new Adw.CallbackAnimationTarget (swipe_animation_target_cb);
			var animation = new Adw.TimedAnimation (this, swipe_progress, 0.0, CANCEL_SWIPE_ANIMATION_DURATION, target) {
				easing = Adw.Easing.EASE_OUT_QUART
			};
			animation.done.connect (on_swipe_animation_end);
			animation.play ();
		} else {
			clear ();
			this.swipe_children_opacity = 1.0;
		}
	}

	private void swipe_animation_target_cb (double value) {
		this.swipe_progress = value;
		this.queue_allocate ();
		this.queue_draw ();
	}

	private void on_swipe_animation_end () {
		this.swipe_children_opacity = 1.0;
	}

	public override void size_allocate (int width, int height, int baseline) {
        int swipe_y_offset = (int) (-height * swipe_progress);
		Gtk.Allocation allocation = Gtk.Allocation () {
			x = 0,
			y = swipe_y_offset,
			width = width,
			height = height
		};
		scale_revealer.allocate_size (allocation, baseline);
    }

	public override void snapshot (Gtk.Snapshot snapshot) {
		double progress = double.min (
			1.0 - swipe_progress.abs (),
			scale_revealer.animation.value
		);

		if (progress > 0.0) {
			Gdk.RGBA background_color = Gdk.RGBA () {
				red = 0.0f,
				green = 0.0f,
				blue = 0.0f,
				alpha = (float) progress
			};
			Graphene.Rect bounds = Graphene.Rect () {
				origin = Graphene.Point () { x = 0.0f, y = 0.0f },
				size = Graphene.Size () { width = (float) this.get_width (), height = (float) this.get_height () }
			};

			snapshot.append_color (background_color, bounds);
		}

		this.snapshot_child (scale_revealer, snapshot);
	}

	public double get_cancel_progress () {
		return 0.0;
	}

	public double get_distance () {
		return (double) this.get_height ();
	}

	public double get_progress () {
		return swipe_progress;
	}

	public double[] get_snap_points () {
		return {-1.0, 0.0, 1.0};
	}

	public Gdk.Rectangle get_swipe_area (Adw.NavigationDirection navigation_direction, bool is_drag) {
		return {
			0,
			0,
			this.get_width (),
			this.get_height ()
		};
	}

	private void on_scale_revealer_transition_end () {
		if (!scale_revealer.reveal_child) {
			this.visible = false;
			swipe_progress = 0.0;
			scale_revealer.source_widget = null;
			reset_media_viewer ();
		}
	}

	int? old_height;
	int? old_width;
	protected void on_scale_changed (double scale) {
		var t_item = safe_get ((int) carousel.position);
		if (t_item != null) {
			if (old_height == null) old_height = t_item.child_height;
			if (old_width == null) old_width = t_item.child_width;

			t_item.zoom (scale, old_width, old_height);
		}
	}

	protected void on_scale_end (Gdk.EventSequence? sequence) {
		old_height = null;
		old_width = null;
	}

	protected void on_motion (double x, double y) {
		on_reveal_media_buttons ();
	}

	uint revealer_timeout = 0;
	protected void on_reveal_media_buttons () {
		page_buttons_revealer.set_reveal_child (true);
		zoom_buttons_revealer.set_reveal_child (true);

		if (revealer_timeout > 0) GLib.Source.remove (revealer_timeout);
		revealer_timeout = Timeout.add (5 * 1000, on_hide_media_buttons, Priority.LOW);
	}

	protected bool on_hide_media_buttons () {
		page_buttons_revealer.set_reveal_child (false);
		zoom_buttons_revealer.set_reveal_child (false);
		revealer_timeout = 0;

		return GLib.Source.REMOVE;
	}

	protected bool on_keypress (uint keyval, uint keycode, Gdk.ModifierType state) {
		if (state != 0) {
			if (state != Gdk.ModifierType.CONTROL_MASK) return false;

			Item? page = safe_get ((int) carousel.position);
			if (page == null) return false;

			switch (keyval) {
				case Gdk.Key.equal:
					page.zoom_in ();
					break;
				case Gdk.Key.minus:
					page.zoom_out ();
					break;
				default:
					return false;
			}

			return true;
		}

		switch (keyval) {
			case Gdk.Key.Left:
			case Gdk.Key.KP_Left:
				scroll_to (((int) carousel.position) - 1, false);
				break;
			case Gdk.Key.Right:
			case Gdk.Key.KP_Right:
				scroll_to (((int) carousel.position) + 1, false);
				break;
			case Gdk.Key.F11:
				toggle_fullscreen ();
				break;
			default:
				return false;
		}

		return true;
	}

	[GtkCallback]
	public void clear () {
		if (!revealed) reset_media_viewer ();
		scale_revealer.reveal_child = false;
	}

	[GtkCallback]
	private void toggle_fullscreen () {
		this.fullscreen = !this._fullscreen;
	}

	private void copy_url () {
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		Host.copy (page.url);
		app.toast (_("Copied media url to clipboard"));
	}

	private void open_in_browser () {
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		Host.open_uri (page.url);
	}

	private void save_as () {
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		Widgets.Attachment.Item.save_media_as (page.url);
	}

	private void on_drag_begin (double x, double y) {
		var t_item = safe_get ((int) carousel.position);
		if (t_item == null) return;

		var pic = t_item.child_widget as Gtk.Picture;
		if (pic != null && t_item.can_zoom_out) {
			pic.set_cursor (new Gdk.Cursor.from_name ("grabbing", null));
			t_item.last_x = 0.0;
			t_item.last_y = 0.0;
		}
	}

	private void on_drag_update (double x, double y) {
		var t_item = safe_get ((int) carousel.position);
		if (t_item == null) return;

		var pic = t_item.child_widget as Gtk.Picture;
		if (pic != null && t_item.can_zoom_out) {
			t_item.update_adjustment (x, y);
			t_item.last_x = x;
			t_item.last_y = y;
		}
	}

	private void on_drag_end (double x, double y) {
		var t_item = safe_get ((int) carousel.position);
		if (t_item == null) return;

		var pic = t_item.child_widget as Gtk.Picture;
		if (pic != null) {
			pic.set_cursor (null);
			t_item.last_x = 0.0;
			t_item.last_y = 0.0;
		};
	}

	private void setup_mouse_previous_click () {
		var gesture = new Gtk.GestureClick ();
		gesture.button = 8;
		gesture.propagation_phase = Gtk.PropagationPhase.CAPTURE;
		gesture.pressed.connect (handle_mouse_previous_click);
		add_controller (gesture);
	}

	private void setup_mouse_secondary_click () {
		var gesture = new Gtk.GestureClick () {
			button = Gdk.BUTTON_SECONDARY,
			propagation_phase = Gtk.PropagationPhase.CAPTURE
		};
		gesture.pressed.connect (on_secondary_click);
		add_controller (gesture);
	}

	private void setup_double_click () {
		var gesture = new Gtk.GestureClick () {
			button = 1
		};
		gesture.pressed.connect (on_double_click);
		add_controller (gesture);
	}

	private void on_secondary_click (int n_press, double x, double y) {
		debug ("Context menu triggered");

		Gdk.Rectangle rectangle = {
			(int) x,
			(int) y,
			0,
			0
		};

		context_menu.set_pointing_to (rectangle);
		context_menu.popup ();
	}

	private void handle_mouse_previous_click (int n_press, double x, double y) {
		clear ();
	}

	private void on_double_click (int n_press, double x, double y) {
		if (n_press != 2) return;

		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		page.on_double_click ();
	}

	private void reset_media_viewer () {
		revealer_widgets.clear ();
		this.fullscreen = false;
		todo_items.clear ();

		items.foreach ((item) => {
			carousel.remove (item);

			return true;
		});

		items.clear ();
		revealed = false;
	}

	private void update_revealer_widget () {
		if (revealed && revealer_widgets.has_key ((int) carousel.position))
			scale_revealer.source_widget = revealer_widgets.get ((int) carousel.position);
	}

	private async string download_video (string url) throws Error {
		return yield Host.download (url);
	}

	private bool revealed = false;
	public void reveal (Gtk.Widget? widget) {
		if (revealed) return;

		this.visible = true;
		scale_revealer.source_widget = widget;
		scale_revealer.reveal_child = true;

		revealed = true;
		do_todo_items ();
	}

	public Gee.HashMap<int, Gtk.Widget> revealer_widgets = new Gee.HashMap<int, Gtk.Widget> ();
	public void add_media (
		string url,
		Tuba.Attachment.MediaType media_type,
		Gdk.Paintable? preview,
		int? pos = null,
		bool as_is = false,
		string? alt_text = null,
		string? user_friendly_url = null,
		bool stream = false,
		Gtk.Widget? revealer_widget = null
	) {
		Item item;
		string final_friendly_url = user_friendly_url == null ? url : user_friendly_url;
		Gdk.Paintable? final_preview = as_is ? null : preview;
		if (revealer_widget != null)
			revealer_widgets.set (pos == null ? items.size : pos, revealer_widget);

		if (media_type.is_video ()) {
			var video = new Gtk.Video ();
			item = new Item (video, final_friendly_url, final_preview, true);

			if (stream) {
				File file = File.new_for_uri (url);
				video.set_file (file);
			} else if (!as_is) {
				download_video.begin (url, (obj, res) => {
					try {
						var path = download_video.end (res);
						video.set_filename (path);
						add_todo_item (item);
					}
					catch (Error e) {
						var dlg = app.inform (_("Error"), e.message);
						dlg.present ();
					}
				});
			}
		} else {
			var picture = new Gtk.Picture ();

			if (!settings.media_viewer_expand_pictures) {
				picture.valign = picture.halign = Gtk.Align.CENTER;
			}

			item = new Item (picture, final_friendly_url, final_preview);
			item.zoom_changed.connect (on_zoom_change);

			if (alt_text != null) picture.alternative_text = alt_text;

			if (!as_is) {
				Tuba.Helper.Image.request_paintable (url, null, (data) => {
					picture.paintable = data;
					if (data != null)
						add_todo_item (item);
				});
			} else {
				picture.paintable = preview;
			}
		}

		if (pos == null) {
			carousel.append (item);
			items.add (item);
		} else {
			carousel.insert (item, pos);
			items.insert (pos, item);
		}

		if (as_is || stream) add_todo_item (item);
	}

	private Gee.ArrayList<string> todo_items = new Gee.ArrayList<string> ();
	private void add_todo_item (Item todo_item) {
		if (revealed) {
			todo_item.done ();
		} else {
			todo_items.add (todo_item.url);
		}
	}
	private void do_todo_items () {
		if (todo_items.size == 0 || items.size == 0) return;

		items.foreach (item => {
			if (todo_items.contains (item.url)) {
				item.done ();
				todo_items.remove (item.url);
			}
			return true;
		});
	}

	public void scroll_to (int pos, bool should_timeout = true) {
		if (pos >= items.size || pos < 0) return;

		if (!should_timeout) {
			carousel.scroll_to (carousel.get_nth_page (pos), true);
			return;
		}

		// https://gitlab.gnome.org/GNOME/libadwaita/-/issues/597
		// https://gitlab.gnome.org/GNOME/libadwaita/-/merge_requests/827
		uint timeout = 0;
		timeout = Timeout.add (250, () => {
			if (pos < items.size)
				carousel.scroll_to (carousel.get_nth_page (pos), true);
			GLib.Source.remove (timeout);

			return true;
		}, Priority.LOW);
	}

	[GtkCallback]
    private void on_previous_clicked () {
        scroll_to (((int) carousel.position) - 1, false);
    }

	[GtkCallback]
    private void on_next_clicked () {
        scroll_to (((int) carousel.position) + 1, false);
    }

	[GtkCallback]
    private void on_zoom_out_clicked () {
        Item? page = safe_get ((int) carousel.position);
			if (page == null) return;

			page.zoom_out ();
    }

	[GtkCallback]
    private void on_zoom_in_clicked () {
        Item? page = safe_get ((int) carousel.position);
			if (page == null) return;

			page.zoom_in ();
    }

	private void on_carousel_page_changed (uint pos) {
		prev_btn.sensitive = pos > 0;
		next_btn.sensitive = pos < items.size - 1;

		Item? page = safe_get ((int) pos);
		// Media buttons overlap the video
		// controller, so position them higher
		if (page != null && page.is_video) {
			page_buttons_revealer.margin_bottom = zoom_buttons_revealer.margin_bottom = 68;
			zoom_buttons_revealer.visible = false;
			play_video ((int) pos);
			copy_media_simple_action.set_enabled (false);
		} else {
			page_buttons_revealer.margin_bottom = zoom_buttons_revealer.margin_bottom = 18;
			zoom_buttons_revealer.visible = true;
			pause_all_videos ();
			copy_media_simple_action.set_enabled (true);
		}

		on_zoom_change ();
	}

	private void on_carousel_n_pages_changed () {
		bool has_more_than_1_item = carousel.n_pages > 1;

		page_buttons_revealer.visible = has_more_than_1_item;
		carousel_dots.visible = has_more_than_1_item;
	}

	public void on_zoom_change () {
		Item? page = safe_get ((int) carousel.position);
		zoom_in_btn.sensitive = page == null ? false : page.can_zoom_in;

		bool can_zoom_out = page == null ? false : page.can_zoom_out;
		zoom_out_btn.sensitive = can_zoom_out;
		carousel.interactive = !can_zoom_out;
		swipe_tracker.enabled = !can_zoom_out;
	}

	// ArrayList will segfault if we #get
	// out of bounds
	private Item? safe_get (int pos) {
		if (items.size > pos && pos > -1) return items.get (pos);

		return null;
	}

	private void play_video (int pos) {
		var i = 0;
		items.foreach (item => {
			item.playing = i == pos;
			i++;
			return true;
		});
	}

	private void pause_all_videos () {
		items.foreach (item => {
			item.playing = false;
			return true;
		});
	}

	protected void copy_media () {
		debug ("Begin copy-media action");
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		Gtk.Picture? pic = page.child_widget as Gtk.Picture;
		if (pic == null || pic.paintable == null) return;

		Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
		Gdk.Texture texture = pic.paintable as Gdk.Texture;
		if (texture == null) return;

		clipboard.set_texture (texture);
		app.toast (_("Copied image to clipboard"));
		debug ("End copy-media action");
	}
}
