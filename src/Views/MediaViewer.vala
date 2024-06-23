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
				if (!is_done) return pre_playing;
				#if CLAPPER
					switch (((ClapperGtk.Video) child_widget).player.state) {
						case Clapper.PlayerState.PAUSED:
						case Clapper.PlayerState.STOPPED:
							return false;
						default:
							return true;
					}
				#else
					return ((Gtk.Video) child_widget).media_stream.playing;
				#endif
			}

			set {
				if (!is_video) return;
				if (is_done) {
					#if CLAPPER
						if (value) {
							((ClapperGtk.Video) child_widget).player.play ();
						} else {
							((ClapperGtk.Video) child_widget).player.pause ();
						}
					#else
						((Gtk.Video) child_widget).media_stream.playing = value;
					#endif
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

			#if GTK_4_14 && !CLAPPER
				if (this.is_video)
					stack.visible_child_name = "child";
			#endif

			if (paintable != null) overlay.child = new Gtk.Picture.for_paintable (paintable);
		}

		~Item () {
			debug ("Destroying MediaViewer.Item");

			if (is_video) {
				#if CLAPPER
					ClapperGtk.Video child_wdgt = (ClapperGtk.Video) child_widget;
					last_used_volume = child_wdgt.player.mute ? 0.0 : child_wdgt.player.volume;
					child_wdgt.player.queue.clear ();
				#else
					Gtk.Video child_wdgt = (Gtk.Video) child_widget;
					last_used_volume = child_wdgt.media_stream.muted ? 0.0 : child_wdgt.media_stream.volume;
					child_wdgt.media_stream.stream_unprepared ();
					child_wdgt.set_file (null);
					child_wdgt.set_media_stream (null);
				#endif
			} else {
				((Gtk.Picture) child_widget).paintable = null;
			}

			child_widget.destroy ();
		}

		ulong media_stream_signal_id = -1;
		public void done () {
			if (is_done) return;

			#if !CLAPPER
				if (is_video && ((Gtk.Video) child_widget).media_stream == null) {
					if (media_stream_signal_id == -1) {
						media_stream_signal_id = ((Gtk.Video) child_widget).notify["media-stream"].connect (on_received_media_stream);
					}

					return;
				};
			#endif

			spinner.spinning = false;
			#if !GTK_4_14 || CLAPPER
				stack.visible_child_name = "child";
			#endif

			if (is_video) {
				#if CLAPPER
					if (pre_playing) {
						((ClapperGtk.Video) child_widget).player.play ();
					} else {
						((ClapperGtk.Video) child_widget).player.pause ();
					}

					((ClapperGtk.Video) child_widget).player.volume = last_used_volume;
					((ClapperGtk.Video) child_widget).player.notify["volume"].connect (on_manual_volume_change);
				#else
					((Gtk.Video) child_widget).media_stream.volume = 1.0 - last_used_volume;
					((Gtk.Video) child_widget).media_stream.volume = last_used_volume;
					((Gtk.Video) child_widget).media_stream.playing = pre_playing;
					((Gtk.Video) child_widget).media_stream.notify["volume"].connect (on_manual_volume_change);
				#endif
			};
			is_done = true;
		}

		private void on_received_media_stream () {
			if (((Gtk.Video) child_widget).media_stream != null) {
				done ();
				((Gtk.Video) child_widget).disconnect (media_stream_signal_id);
			}
		}

		private void on_manual_volume_change () {
			settings.media_viewer_last_used_volume =
			#if CLAPPER
				((ClapperGtk.Video) child_widget).player.volume;
			#else
				((Gtk.Video) child_widget).media_stream.volume;
			#endif
		}

		private bool on_scroll (Gtk.EventControllerScroll scroll, double dx, double dy) {
			var state = scroll.get_current_event_state () & Gdk.MODIFIER_MASK;
			if (state != Gdk.ModifierType.CONTROL_MASK)
				return false;

			if (dy < 0)
				zoom_in ();
			else
				zoom_out ();

			return true;
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

			var scroll = new Gtk.EventControllerScroll (Gtk.EventControllerScrollFlags.BOTH_AXES | Gtk.EventControllerScrollFlags.DISCRETE);
			scroll.scroll.connect (on_scroll);
			scroller.add_controller (scroll);

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
			} else {
				app.main_window.unfullscreen ();
				fullscreen_btn.icon_name = "view-fullscreen-symbolic";
			}

			_fullscreen =
			toggle_fs_revealer.visible = value;
			headerbar.visible = !value;
		}
		get { return app.main_window.fullscreened; }
	}

	private const GLib.ActionEntry[] ACTION_ENTRIES = {
		{"copy-url", copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as", save_as},
		{"fullscreen", toggle_fullscreen},
		{"zoom-in", zoom_in_action},
		{"zoom-out", zoom_out_action},
		{"scroll-next", on_next_clicked},
		{"scroll-back", on_previous_clicked}
	};

	private Gee.ArrayList<Item> items = new Gee.ArrayList<Item> ();
	protected SimpleAction copy_media_simple_action;

	[GtkChild] unowned Gtk.PopoverMenu context_menu;
	[GtkChild] unowned Gtk.Button fullscreen_btn;
	[GtkChild] unowned Adw.HeaderBar headerbar;
	[GtkChild] unowned Gtk.Button back_btn;
	[GtkChild] unowned Gtk.Revealer toggle_fs_revealer;

	[GtkChild] unowned Gtk.Revealer page_buttons_revealer;
	[GtkChild] unowned Gtk.Button prev_btn;
	[GtkChild] unowned Gtk.Button next_btn;

	[GtkChild] unowned Gtk.Revealer zoom_buttons_revealer;
	[GtkChild] unowned Gtk.Button zoom_out_btn;
	[GtkChild] unowned Gtk.Button zoom_in_btn;

	[GtkChild] unowned Tuba.Widgets.ScaleRevealer scale_revealer;
	[GtkChild] unowned Adw.Carousel carousel;

	private double swipe_children_opacity {
		set {
			headerbar.opacity =
			page_buttons_revealer.opacity =
			toggle_fs_revealer.opacity =
			zoom_buttons_revealer.opacity = value;
		}
	}

	construct {
		#if CLAPPER
			// Clapper can have > 1.0 volumes
			last_used_volume = settings.media_viewer_last_used_volume;
		#else
			last_used_volume = settings.media_viewer_last_used_volume.clamp (0.0, 1.0);
		#endif

		if (is_rtl) back_btn.icon_name = "tuba-right-large-symbolic";

		var shortcutscontroller = new Gtk.ShortcutController ();
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("Escape"),
			new Gtk.NamedAction ("app.back")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Alt>Left"),
			new Gtk.NamedAction ("app.back")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("Pointer_DfltBtnPrev"),
			new Gtk.NamedAction ("app.back")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("F11"),
			new Gtk.NamedAction ("mediaviewer.fullscreen")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl>plus"),
			new Gtk.NamedAction ("mediaviewer.zoom-in")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl><Shift>plus"),
			new Gtk.NamedAction ("mediaviewer.zoom-in")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl>equal"),
			new Gtk.NamedAction ("mediaviewer.zoom-in")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl><Shift>equal"),
			new Gtk.NamedAction ("mediaviewer.zoom-in")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl>KP_Add"),
			new Gtk.NamedAction ("mediaviewer.zoom-in")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl><Shift>KP_Add"),
			new Gtk.NamedAction ("mediaviewer.zoom-in")
		));

		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl>minus"),
			new Gtk.NamedAction ("mediaviewer.zoom-out")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl><Shift>minus"),
			new Gtk.NamedAction ("mediaviewer.zoom-out")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl>underscore"),
			new Gtk.NamedAction ("mediaviewer.zoom-out")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl><Shift>underscore"),
			new Gtk.NamedAction ("mediaviewer.zoom-out")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl>KP_Subtract"),
			new Gtk.NamedAction ("mediaviewer.zoom-out")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("<Ctrl><Shift>KP_Subtract"),
			new Gtk.NamedAction ("mediaviewer.zoom-out")
		));

		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("Left"),
			new Gtk.NamedAction ("mediaviewer.scroll-back")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("KP_Left"),
			new Gtk.NamedAction ("mediaviewer.scroll-back")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("Right"),
			new Gtk.NamedAction ("mediaviewer.scroll-next")
		));
		shortcutscontroller.add_shortcut (new Gtk.Shortcut (
			Gtk.ShortcutTrigger.parse_string ("KP_Right"),
			new Gtk.NamedAction ("mediaviewer.scroll-next")
		));
		add_controller (shortcutscontroller);

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
		setup_mouse1_click ();
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
		swipe_tracker.update_swipe.connect (on_update_swipe);
		swipe_tracker.end_swipe.connect (on_end_swipe);
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

	public override void measure (
		Gtk.Orientation orientation,
		int for_size,
		out int minimum,
		out int natural,
		out int minimum_baseline,
		out int natural_baseline
	) {
		this.scale_revealer.measure (
			orientation,
			for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);
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
			return;
		}

		revealed = true;
		if (load_and_scroll_to != -1) {
			var scroll_to_widget = safe_get (load_and_scroll_to);
			do_todo_item (scroll_to_widget);
			for (int i = 0; i < load_and_scroll_to; i++) {
				var item = safe_get (i);
				if (item != null) {
					item.visible = true;
					carousel.scroll_to (scroll_to_widget, false);
				} else break;
			}
		}

		do_todo_items ();
		on_carousel_page_changed ((int) carousel.position);
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

	double on_motion_last_x = 0.0;
	double on_motion_last_y = 0.0;
	protected void on_motion (double x, double y) {
		if (on_motion_last_x == x && on_motion_last_y == y) return;
		on_motion_last_x = x;
		on_motion_last_y = y;

		on_reveal_media_buttons ();
	}

	uint revealer_timeout = 0;
	protected void on_reveal_media_buttons () {
		page_buttons_revealer.set_reveal_child (true);
		zoom_buttons_revealer.set_reveal_child (true);
		toggle_fs_revealer.set_reveal_child (true);

		if (revealer_timeout > 0) GLib.Source.remove (revealer_timeout);
		revealer_timeout = Timeout.add (5 * 1000, on_hide_media_buttons, Priority.LOW);
	}

	protected bool on_hide_media_buttons () {
		page_buttons_revealer.set_reveal_child (false);
		zoom_buttons_revealer.set_reveal_child (false);
		toggle_fs_revealer.set_reveal_child (false);
		revealer_timeout = 0;

		return GLib.Source.REMOVE;
	}

	private void zoom_in_action () {
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		page.zoom_in ();
	}

	private void zoom_out_action () {
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		page.zoom_out ();
	}

	[GtkCallback]
	public void clear () {
		if (!revealed) reset_media_viewer ();
		scale_revealer.reveal_child = false;
		load_and_scroll_to = -1;
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

		Host.open_url (page.url);
	}

	private void save_as () {
		Item? page = safe_get ((int) carousel.position);
		if (page == null) return;

		Widgets.Attachment.Item.save_media_as.begin (page.url);
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

	private void setup_mouse1_click () {
		var gesture = new Gtk.GestureClick () {
			button = 1
		};
		gesture.pressed.connect (on_mouse1_click);
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

	private void on_mouse1_click (int n_press, double x, double y) {
		switch (n_press) {
			case 1:
				on_reveal_media_buttons ();
				break;
			case 2:
				Item? page = safe_get ((int) carousel.position);
				if (page == null) break;

				page.on_double_click ();
				break;
		}
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

	private void update_revealer_widget (int pos = -1) {
		int new_pos = pos == -1 ? (int) carousel.position : pos;
		if (revealed && revealer_widgets.has_key (new_pos))
			scale_revealer.source_widget = revealer_widgets.get (new_pos);
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
	}

	int load_and_scroll_to = -1;
	public Gee.HashMap<int, Gtk.Widget> revealer_widgets = new Gee.HashMap<int, Gtk.Widget> ();
	public void add_media (
		string url,
		Tuba.Attachment.MediaType media_type,
		Gdk.Paintable? preview,
		bool as_is = false,
		string? alt_text = null,
		string? user_friendly_url = null,
		bool stream = false,
		Gtk.Widget? revealer_widget = null,
		bool? load_and_scroll = null
	) {
		Item item;
		string final_friendly_url = user_friendly_url == null ? url : user_friendly_url;
		Gdk.Paintable? final_preview = as_is ? null : preview;
		if (revealer_widget != null)
			revealer_widgets.set (items.size, revealer_widget);

		if (media_type.is_video ()) {
			#if CLAPPER
				var video = new ClapperGtk.Video () {
					auto_inhibit = true
				};
				video.add_fading_overlay (new ClapperGtk.SimpleControls () {
					valign = Gtk.Align.END,
					fullscreenable = false
				});
				#if CLAPPER_MPRIS
				    var mpris = new Clapper.Mpris (
				      "org.mpris.MediaPlayer2.Tuba",
				      Build.NAME,
					  null
					);
				    video.player.add_feature (mpris);
				#endif
				video.player.audio_filter = Gst.ElementFactory.make ("scaletempo", null);
			#else
				var video = new Gtk.Video () {
					#if GTK_4_14
						graphics_offload = settings.use_graphics_offload ? Gtk.GraphicsOffloadEnabled.ENABLED : Gtk.GraphicsOffloadEnabled.DISABLED
					#endif
				};
			#endif

			if (media_type == Tuba.Attachment.MediaType.GIFV) {
				#if CLAPPER
					video.player.autoplay = true;
				#else
					video.loop = true;
					video.autoplay = true;
				#endif
			}

			item = new Item (video, final_friendly_url, final_preview, true);

			#if CLAPPER
				var clp_item = new Clapper.MediaItem (url);
				video.player.queue.add_item (clp_item);
				video.player.queue.select_item (clp_item);
				add_todo_item (item);
			#else
				if (stream) {
					File file = File.new_for_uri (url);
					video.set_file (file);
					add_todo_item (item);
				} else if (!as_is) {
					download_video.begin (url, (obj, res) => {
						try {
							var path = download_video.end (res);
							video.set_filename (path);
							add_todo_item (item);
						} catch (Error e) {
							var dlg = app.inform (_("Error"), e.message);
							dlg.present (app.main_window);
						}
					});
				}
			#endif
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

		if (load_and_scroll == false && load_and_scroll_to == -1) item.visible = false;
		if (load_and_scroll == true) load_and_scroll_to = items.size;
		carousel.append (item);
		items.add (item);

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

	private void do_todo_item (Item item) {
		item.done ();
		todo_items.remove (item.url);
	}

	private void do_todo_items () {
		if (todo_items.size == 0 || items.size == 0) return;

		items.foreach (item => {
			if (todo_items.contains (item.url)) {
				do_todo_item (item);
			}
			return true;
		});
	}

	public void scroll_to (int pos, bool animate = true) {
		if (pos >= items.size || pos < 0) return;
		carousel.scroll_to (carousel.get_nth_page (pos), animate);
	}

	[GtkCallback]
	private void on_previous_clicked () {
		scroll_to (((int) carousel.position) - 1);
	}

	[GtkCallback]
	private void on_next_clicked () {
		scroll_to (((int) carousel.position) + 1);
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
		update_revealer_widget ((int) pos);

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
		page_buttons_revealer.visible = carousel.n_pages > 1;
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
