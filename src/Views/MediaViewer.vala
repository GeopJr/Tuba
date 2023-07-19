// Mostly inspired by Loupe https://gitlab.gnome.org/Incubator/loupe

public class Tuba.Views.MediaViewer : Gtk.Box {
    const double MAX_ZOOM = 20;
    private signal void zoom_changed ();

    public class Item : Adw.Bin {
        private Gtk.Stack stack;
        private Gtk.Overlay overlay;
        private Gtk.Spinner spinner;
        private Gtk.ScrolledWindow scroller;

        private Views.MediaViewer? media_viewer { get; set; default=null; }
        public Gtk.Widget child_widget { get; private set; }
        public bool is_video { get; private set; default=false; }
        public string url { get; private set; }
        public double last_x { get; set; default=0.0; }
        public double last_y { get; set; default=0.0; }

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
            Views.MediaViewer? t_media_viewer = null,
            bool t_is_video = false
        ) {
            media_viewer = t_media_viewer;
            child_widget = child;
            is_video = t_is_video;

            stack.add_named (setup_scrolledwindow (child), "child");
            this.url = t_url;

            if (paintable != null) overlay.child = new Gtk.Picture.for_paintable (paintable);
        }

        public Item.static (Gtk.Widget child, string t_url, Views.MediaViewer? t_media_viewer = null) {
            media_viewer = t_media_viewer;
            child_widget = child;

            stack.add_named (setup_scrolledwindow (child), "child");
            this.url = t_url;

            done ();
        }

        ~Item () {
            message ("Destroying MediaViewer.Item");

            if (is_video) {
                ((Gtk.Video) child_widget).media_stream.stream_unprepared ();
                ((Gtk.Video) child_widget).set_file (null);
                ((Gtk.Video) child_widget).set_media_stream (null);
            } else {
                ((Gtk.Picture) child_widget).paintable = null;
            }

            child_widget.destroy ();
        }

        public void done () {
            spinner.spinning = false;
            stack.visible_child_name = "child";
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
            if (media_viewer != null) media_viewer.zoom_changed ();
        }
    }

    private bool _fullscreen = false;
	public bool fullscreen {
		set {
            if (value) {
                app.main_window.fullscreen ();
                fullscreen_btn.icon_name = "tuba-view-restore-symbolic";
                _fullscreen = true;
            } else {
                app.main_window.unfullscreen ();
                fullscreen_btn.icon_name = "tuba-view-fullscreen-symbolic";
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
	protected Gtk.Button fullscreen_btn;
	protected Adw.HeaderBar headerbar;
    private Adw.Carousel carousel;
    private Adw.CarouselIndicatorDots carousel_dots;

	construct {
        carousel = new Adw.Carousel () {
            vexpand = true,
            hexpand = true
        };

        // Move between media using the arrow keys
        var keypresscontroller = new Gtk.EventControllerKey ();
        keypresscontroller.key_pressed.connect (on_keypress);
        add_controller (keypresscontroller);

        var overlay = new Gtk.Overlay () {
            vexpand = true,
            hexpand = true
        };

        Gtk.Widget zoom_btns;
        Gtk.Widget page_btns;
        generate_media_buttons (out page_btns, out zoom_btns);

        overlay.add_overlay (page_btns);
        overlay.add_overlay (zoom_btns);
        overlay.child = carousel;

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

		orientation = Gtk.Orientation.VERTICAL;
        spacing = 0;

        var actions = new GLib.SimpleActionGroup ();
		actions.add_action_entries (ACTION_ENTRIES, this);
		this.insert_action_group ("mediaviewer", actions);

		headerbar = new Adw.HeaderBar () {
            title_widget = new Gtk.Label (_("Media Viewer")) {
                css_classes = {"title"}
            },
			css_classes = {"flat"}
        };
        var back_btn = new Gtk.Button.from_icon_name ("tuba-left-large-symbolic") {
            tooltip_text = _("Go Back")
        };
        back_btn.clicked.connect (on_back_clicked);
        headerbar.pack_start (back_btn);

        var end_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        fullscreen_btn = new Gtk.Button.from_icon_name ("tuba-view-fullscreen-symbolic") {
            tooltip_text = _("Toggle Fullscreen")
        };
        fullscreen_btn.clicked.connect (toggle_fullscreen);

        var actions_btn = new Gtk.MenuButton () {
            icon_name = "tuba-view-more-symbolic",
            menu_model = create_actions_menu ()
        };

        end_box.append (fullscreen_btn);
        end_box.append (actions_btn);
        headerbar.pack_end (end_box);

        carousel_dots = new Adw.CarouselIndicatorDots () {
            carousel = carousel,
            visible = false
        };

		carousel.bind_property ("n_pages", carousel_dots, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean (src.get_uint () > 1);
			return true;
		});

        append (headerbar);
        append (overlay);
        append (carousel_dots);

		setup_mouse_previous_click ();
        setup_double_click ();
	}
	~MediaViewer () {
		message ("Destroying MediaViewer");
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
        // Don't handle it if there's
        // a modifier
        if (state != 0) return false;

        switch (keyval) {
            case Gdk.Key.Left:
            case Gdk.Key.KP_Left:
                scroll_to (((int) carousel.position) - 1, false);
                break;
            case Gdk.Key.Right:
            case Gdk.Key.KP_Right:
                scroll_to (((int) carousel.position) + 1, false);
                break;
            default:
                return false;
        }

        return true;
    }

    protected void on_back_clicked () {
        clear ();
    }

    protected void toggle_fullscreen () {
        this.fullscreen = !this._fullscreen;
    }

    protected GLib.Menu create_actions_menu () {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "mediaviewer.open-in-browser");
		menu_model.append (_("Copy URL"), "mediaviewer.copy-url");
		menu_model.append (_("Save Media"), "mediaviewer.save-as");

        return menu_model;
	}

    private void copy_url () {
		Host.copy (safe_get ((int) carousel.position)?.url);
	}

	private void open_in_browser () {
		Host.open_uri (safe_get ((int) carousel.position)?.url);
	}

	private void save_as () {
		Widgets.Attachment.Item.save_media_as (safe_get ((int) carousel.position)?.url);
	}

    private void on_drag_begin (double x, double y) {
        var t_item = safe_get ((int) carousel.position);
        var pic = t_item?.child_widget as Gtk.Picture;
        if (pic != null && t_item.can_zoom_out) {
            pic.set_cursor (new Gdk.Cursor.from_name ("grabbing", null));
            t_item.last_x = 0.0;
            t_item.last_y = 0.0;
        }
    }

    private void on_drag_update (double x, double y) {
        var t_item = safe_get ((int) carousel.position);
        var pic = t_item?.child_widget as Gtk.Picture;
        if (pic != null && t_item.can_zoom_out) {
            t_item.update_adjustment (x, y);
            t_item.last_x = x;
            t_item.last_y = y;
        }
    }

    private void on_drag_end (double x, double y) {
        var t_item = safe_get ((int) carousel.position);
        var pic = t_item?.child_widget as Gtk.Picture;
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

    private void setup_double_click () {
        var gesture = new Gtk.GestureClick () {
            button = 1
        };
        gesture.pressed.connect (on_double_click);
        add_controller (gesture);
    }

    private void handle_mouse_previous_click (int n_press, double x, double y) {
        on_back_clicked ();
    }

    private void on_double_click (int n_press, double x, double y) {
        if (n_press != 2) return;
        safe_get ((int) carousel.position)?.on_double_click ();
    }

	public virtual signal void clear () {
        this.fullscreen = false;

        items.foreach ((item) => {
            carousel.remove (item);

            return true;
        });

        items.clear ();
    }

    private async string download_video (string url) throws Error {
		return yield Host.download (url);
	}

    public void add_video (string url, Gdk.Paintable? preview, int? pos) {
        var video = new Gtk.Video () {
            autoplay = true
        };
        var item = new Item (video, url, preview, null, true);
        if (pos == null) {
            carousel.append (item);
            items.add (item);
        } else {
            carousel.insert (item, pos);
            items.insert (pos, item);
        }

		download_video.begin (url, (obj, res) => {
			try {
				var path = download_video.end (res);
                video.set_filename (path);
                item.done ();
			}
			catch (Error e) {
				var dlg = app.inform (_("Error"), e.message);
                dlg.present ();
			}
		});
	}

    public void add_image (string url, string? alt_text, Gdk.Paintable? preview, int? pos) {
        var picture = new Gtk.Picture ();

        if (!settings.media_viewer_expand_pictures) {
            picture.valign = picture.halign = Gtk.Align.CENTER;
        }

        var item = new Item (picture, url, preview, this);
        if (pos == null) {
            carousel.append (item);
            items.add (item);
        } else {
            carousel.insert (item, pos);
            items.insert (pos, item);
        }

        if (alt_text != null) picture.alternative_text = alt_text;

		image_cache.request_paintable (url, (is_loaded, data) => {
            picture.paintable = data;
            if (is_loaded) {
                item.done ();
            }
        });
    }

    public void set_remote_video (string url, Gdk.Paintable? preview, string? user_friendly_url = null) {
        var video = new Gtk.Video () {
            autoplay = true
        };
        var item = new Item (video, user_friendly_url, preview, null, true);

        File file = File.new_for_uri (url);
		video.set_file (file);
        item.done ();

        carousel.append (item);
        items.add (item);

        carousel.page_changed (0);
    }

    public void set_single_paintable (string url, Gdk.Paintable paintable) {
        var picture = new Gtk.Picture ();
        picture.paintable = paintable;

        if (!settings.media_viewer_expand_pictures) {
            picture.valign = picture.halign = Gtk.Align.CENTER;
        }

        var item = new Item.static (picture, url, this);
        carousel.append (item);
        items.add (item);
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
		timeout = Timeout.add (1000, () => {
            if (pos < items.size)
                carousel.scroll_to (carousel.get_nth_page (pos), true);
			GLib.Source.remove (timeout);

			return true;
		}, Priority.LOW);
    }

    private Gtk.Button zoom_out_btn;
    private Gtk.Button zoom_in_btn;
    private Gtk.Revealer page_buttons_revealer;
    private Gtk.Revealer zoom_buttons_revealer;
    private void generate_media_buttons (out Gtk.Revealer page_btns, out Gtk.Revealer zoom_btns) {
        var t_page_btns = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);
        var t_zoom_btns = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

        var prev_btn = new Gtk.Button.from_icon_name ("go-previous-symbolic") {
            css_classes = {"circular", "osd", "media-viewer-fab"},
            tooltip_text = _("Previous Attachment")
        };

        var next_btn = new Gtk.Button.from_icon_name ("go-next-symbolic") {
            css_classes = {"circular", "osd", "media-viewer-fab"},
            tooltip_text = _("Next Attachment")
        };

        prev_btn.clicked.connect (() => scroll_to (((int) carousel.position) - 1, false));
        next_btn.clicked.connect (() => scroll_to (((int) carousel.position) + 1, false));

        carousel.notify["n-pages"].connect (() => {
            var has_more_than_1_item = carousel.n_pages > 1;

            prev_btn.visible = has_more_than_1_item;
            next_btn.visible = has_more_than_1_item;
        });

        t_page_btns.append (prev_btn);
        t_page_btns.append (next_btn);

        zoom_out_btn = new Gtk.Button.from_icon_name ("zoom-out-symbolic") {
            css_classes = {"circular", "osd", "media-viewer-fab"},
            tooltip_text = _("Zoom Out")
        };

        zoom_in_btn = new Gtk.Button.from_icon_name ("zoom-in-symbolic") {
            css_classes = {"circular", "osd", "media-viewer-fab"},
            tooltip_text = _("Zoom In")
        };

        zoom_out_btn.clicked.connect (() => safe_get ((int) carousel.position)?.zoom_out ());
        zoom_in_btn.clicked.connect (() => safe_get ((int) carousel.position)?.zoom_in ());

        carousel.page_changed.connect ((pos) => {
            prev_btn.sensitive = pos > 0;
            next_btn.sensitive = pos < items.size - 1;

            // Media buttons overlap the video
            // controller, so position them higher
            if (safe_get ((int) pos)?.is_video) {
                page_buttons_revealer.margin_bottom = zoom_buttons_revealer.margin_bottom = 68;
                zoom_buttons_revealer.visible = false;
            } else {
                page_buttons_revealer.margin_bottom = zoom_buttons_revealer.margin_bottom = 18;
                zoom_buttons_revealer.visible = true;
            }

            on_zoom_change ();
        });

        zoom_changed.connect (on_zoom_change);

        t_zoom_btns.append (zoom_out_btn);
        t_zoom_btns.append (zoom_in_btn);

        zoom_buttons_revealer = new Gtk.Revealer () {
            child = t_zoom_btns,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            valign = Gtk.Align.END,
            halign = Gtk.Align.END,
            margin_end = 18,
            margin_bottom = 18,
            visible = false
        };

        page_buttons_revealer = new Gtk.Revealer () {
            child = t_page_btns,
            transition_type = Gtk.RevealerTransitionType.CROSSFADE,
            valign = Gtk.Align.END,
            halign = Gtk.Align.START,
            margin_start = 18,
            margin_bottom = 18
        };

        page_btns = page_buttons_revealer;
        zoom_btns = zoom_buttons_revealer;
    }

    public void on_zoom_change () {
        zoom_in_btn.sensitive = safe_get ((int) carousel.position)?.can_zoom_in;

        bool can_zoom_out = safe_get ((int) carousel.position)?.can_zoom_out ?? false;
        zoom_out_btn.sensitive = can_zoom_out;
        carousel.interactive = !can_zoom_out;
    }

    // ArrayList will segfault if we #get
    // out of bounds
    private Item? safe_get (int pos) {
        if (items.size > pos) return items.get (pos);

        return null;
    }
}
