// Mostly inspired by Loupe https://gitlab.gnome.org/Incubator/loupe

public class Tuba.Views.MediaViewer : Gtk.Box {
    const double MAX_ZOOM = 3.5;
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
                return total_zoom < MAX_ZOOM;
            }
        }

        public bool can_zoom_out {
            get {
                // If either horizontal or vertical scrollbar is visible,
                // you should also be able to zoom out
                return total_zoom > 1.0 && (scroller.hadjustment.upper > scroller.hadjustment.page_size || scroller.vadjustment.upper > scroller.vadjustment.page_size);
            }
        }

        private double _total_zoom = 1.0;
        private double total_zoom {
            get {
                return _total_zoom;
            }

            set {
                _total_zoom = value;
                emit_zoom_changed ();
            }
        }

        public void update_adjustment (double x, double y) {
            scroller.hadjustment.value = scroller.hadjustment.value - x + last_x;
            scroller.vadjustment.value = scroller.vadjustment.value - y + last_y;
        }

        public void zoom (double zoom_level) {
            // Don't zoom on video
            if (is_video) return;

            var diff = total_zoom + zoom_level - 1;
            if (diff <= 1.0) {
                ((Gtk.Picture) child_widget).can_shrink = true;
                child_widget.set_size_request(-1, -1);
                total_zoom = 1.0;

                return;
            } else if (diff > MAX_ZOOM) {
                total_zoom = MAX_ZOOM;

                return;
            }

            ((Gtk.Picture) child_widget).can_shrink = false;
            
            var new_width = child_widget.get_width () * zoom_level;
            var new_height = child_widget.get_height () * zoom_level;
            child_widget.set_size_request( (int) new_width,  (int) new_height);

            // Center the viewport
            scroller.vadjustment.upper = new_height;
            scroller.vadjustment.value = (new_height - scroller.vadjustment.page_size) / 2;

            scroller.hadjustment.upper = new_width;
            scroller.hadjustment.value = (new_width - scroller.hadjustment.page_size) / 2;

            total_zoom = diff;
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
            spinner = new Gtk.Spinner() {
                spinning = true,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                vexpand = true,
                hexpand = true,
                width_request = 32,
                height_request = 32
            };

            overlay.add_overlay (spinner);
            stack.add_named(overlay, "spinner");
            this.child = stack;
        }

        public Item (Gtk.Widget child, string t_url, Gdk.Paintable? paintable, Views.MediaViewer? t_media_viewer = null, bool t_is_video = false) {
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

        private void emit_zoom_changed () {
            if (media_viewer != null) media_viewer.zoom_changed ();
        }
    }

    private bool _fullscreen = false;
	public bool fullscreen {
		set {
            if (value) {
                app.main_window.fullscreen();
                fullscreen_btn.icon_name = "tuba-view-restore-symbolic";
                _fullscreen = true;
            } else {
                app.main_window.unfullscreen();
                fullscreen_btn.icon_name = "tuba-view-fullscreen-symbolic";
                _fullscreen = false;
            }
        }
		get { return app.main_window.fullscreened; }
	}

    private const GLib.ActionEntry[] action_entries = {
		{"copy-url",        copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as",         save_as},
	};

    private Gee.ArrayList<Item> items = new Gee.ArrayList<Item> ();
	protected Gtk.Button fullscreen_btn;
	protected Adw.HeaderBar headerbar;
    protected ImageCache image_cache;
    private Adw.Carousel carousel;
    private Adw.CarouselIndicatorDots carousel_dots;

	construct {
        carousel = new Adw.Carousel () {
            vexpand = true,
            hexpand = true,
            css_classes = {"osd"}
        };

        // Move between media using the arrow keys
        var keypresscontroller = new Gtk.EventControllerKey ();
        keypresscontroller.key_pressed.connect (on_keypress);
        add_controller (keypresscontroller);

        var overlay = new Gtk.Overlay () {
            vexpand = true,
            hexpand = true
        };
        overlay.add_overlay (generate_media_buttons ());
        overlay.child = carousel;

        image_cache = new ImageCache () {
            maintenance_secs = 60 * 5
        };

        var drag = new Gtk.GestureDrag ();
        drag.drag_begin.connect(on_drag_begin);
        drag.drag_update.connect(on_drag_update);
        drag.drag_end.connect(on_drag_end);
        add_controller (drag);

        // Pinch to zoom
        var gesture = new Gtk.GestureZoom();
        gesture.scale_changed.connect((zm) => safe_get ((int) carousel.position)?.zoom (zm));
        add_controller (gesture);

		orientation = Gtk.Orientation.VERTICAL;
        spacing = 0;

        var actions = new GLib.SimpleActionGroup ();
		actions.add_action_entries (action_entries, this);
		this.insert_action_group ("mediaviewer", actions);

		headerbar = new Adw.HeaderBar() {
            title_widget = new Gtk.Label(_("Media Viewer")) {
                css_classes = {"title"}
            },
			css_classes = {"flat", "media-viewer-headerbar"}
        };
        var back_btn = new Gtk.Button.from_icon_name("tuba-left-large-symbolic") {
            tooltip_text = _("Go Back")
        };
        back_btn.clicked.connect(on_back_clicked);
        headerbar.pack_start(back_btn);

        var end_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        fullscreen_btn = new Gtk.Button.from_icon_name("tuba-view-fullscreen-symbolic") {
            tooltip_text = _("Toggle Fullscreen")
        };
        fullscreen_btn.clicked.connect(toggle_fullscreen);
        
        var actions_btn = new Gtk.MenuButton() {
            icon_name = "tuba-view-more-symbolic",
            menu_model = create_actions_menu()
        };

        end_box.append(fullscreen_btn);
        end_box.append(actions_btn);
        headerbar.pack_end(end_box);

        carousel_dots = new Adw.CarouselIndicatorDots () {
            carousel = carousel,
            css_classes = {"osd"},
            visible = false
        };

		carousel.bind_property("n_pages", carousel_dots, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean (src.get_uint () > 1);
			return true;
		});

        append(headerbar);
        append(overlay);
        append(carousel_dots);

		setup_mouse_previous_click();
	}
	~MediaViewer () {
		message ("Destroying MediaViewer");
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

    protected void on_back_clicked() {
        clear();
    }

    protected void toggle_fullscreen() {
        this.fullscreen = !this._fullscreen;
    }

    protected GLib.Menu create_actions_menu() {
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
		Widgets.Attachment.Item.save_media_as(safe_get ((int) carousel.position)?.url);
	}

    private void on_drag_begin (double x, double y) {
        var t_item = safe_get ((int) carousel.position);
        var pic = t_item?.child_widget as Gtk.Picture;
        if (pic != null && !pic.can_shrink) {
            pic.set_cursor (new Gdk.Cursor.from_name ("grabbing", null));
            t_item.last_x = 0.0;
            t_item.last_y = 0.0;
        }
    }

    private void on_drag_update (double x, double y) {
        var t_item = safe_get ((int) carousel.position);
        var pic = t_item?.child_widget as Gtk.Picture;
        if (pic != null && !pic.can_shrink) {
            t_item.update_adjustment (x, y);
            t_item.last_x = x;
            t_item.last_y = y;
        }
    }

    private void on_drag_end (double x, double y) {
        // Don't clear if the image is zoomed in
        // as it triggers when scrolling
        var t_item = safe_get ((int) carousel.position);
        var pic = t_item?.child_widget as Gtk.Picture;
        if (pic != null) {
            pic.set_cursor (null);
            t_item.last_x = 0.0;
            t_item.last_y = 0.0;

            if (!pic.can_shrink) return;
        };

        if (Math.fabs(y) >= 200) {
            on_back_clicked();
        }
    }

    private void setup_mouse_previous_click () {
        var gesture = new Gtk.GestureClick();
        gesture.button = 8;
        gesture.propagation_phase = Gtk.PropagationPhase.CAPTURE;
        gesture.pressed.connect(handle_mouse_previous_click);
        add_controller (gesture);
    }

    private void handle_mouse_previous_click(int n_press, double x, double y) {
        on_back_clicked();
    }

	public virtual signal void clear () {
        this.fullscreen = false;

        items.foreach((item) => {
            carousel.remove(item);

            return true;
        });

        items.clear ();
    }

    private async string download_video (string url) throws Error {
		return yield Host.download (url);
	}

    public void add_video (string url, Gdk.Paintable? preview, int? pos) {
        var video = new Gtk.Video ();
        var item = new Item (video, url, preview, null, true);
        if (pos == null) {
            carousel.append (item);
            items.add (item);
        } else {
            carousel.insert(item, pos);
            items.insert (pos, item);
        }

		download_video.begin (url, (obj, res) => {
			try {
				var path = download_video.end (res);
                video.set_filename(path);
                item.done ();
			}
			catch (Error e) {
				var dlg = app.inform (_("Error"), e.message);
                dlg.present ();
			}
		});
	}

    public void add_image(string url, string? alt_text, Gdk.Paintable? preview, int? pos) {
        var picture = new Gtk.Picture ();
        var item = new Item (picture, url, preview, this);
        if (pos == null) {
            carousel.append (item);
            items.add (item);
        } else {
            carousel.insert(item, pos);
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
        var video = new Gtk.Video ();
        var item = new Item (video, user_friendly_url, preview, null, true);

        File file = File.new_for_uri (url);
		video.set_file(file);
        item.done ();

        carousel.append (item);
        items.add (item);

        carousel.page_changed (0);
    }

    public void set_single_paintable (string url, Gdk.Paintable paintable) {
        var picture = new Gtk.Picture ();
        picture.paintable = paintable;

        var item = new Item.static (picture, url, this);
        carousel.append (item);
        items.add (item);
    }

    public void scroll_to (int pos, bool should_timeout = true) {
        if (pos >= items.size || pos < 0) return;

        if (!should_timeout) {
            carousel.scroll_to(carousel.get_nth_page(pos), true);
            return;
        }

        // https://gitlab.gnome.org/GNOME/libadwaita/-/issues/597
        // https://gitlab.gnome.org/GNOME/libadwaita/-/merge_requests/827
        uint timeout = 0;
		timeout = Timeout.add (1000, () => {
            if (pos < items.size)
                carousel.scroll_to(carousel.get_nth_page(pos), true);
			GLib.Source.remove(timeout);

			return true;
		}, Priority.LOW);
    }

    private Gtk.Button zoom_out_btn;
    private Gtk.Button zoom_in_btn;
    private Gtk.Box generate_media_buttons () {
        var media_buttons = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0) {
            hexpand = true,
            valign = Gtk.Align.END,
            margin_end = 18,
            margin_start = 18,
            margin_bottom = 18
        };

        var page_btns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            valign = Gtk.Align.END,
            halign = Gtk.Align.START
        };

        var zoom_btns = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 12) {
            valign = Gtk.Align.END,
            halign = Gtk.Align.END,
            hexpand = true,
            visible = false
        };

        var prev_btn = new Gtk.Button.from_icon_name("go-previous-symbolic") {
            css_classes = {"circular", "osd"},
            tooltip_text = _("Previous Attachment")
        };

        var next_btn = new Gtk.Button.from_icon_name("go-next-symbolic") {
            css_classes = {"circular", "osd"},
            tooltip_text = _("Next Attachment")
        };

        prev_btn.clicked.connect (() => scroll_to (((int) carousel.position) - 1, false));
        next_btn.clicked.connect (() => scroll_to (((int) carousel.position) + 1, false));

        carousel.notify["n-pages"].connect (() => {
            var has_more_than_1_item = carousel.n_pages > 1;

            prev_btn.visible = has_more_than_1_item;
            next_btn.visible = has_more_than_1_item;
        });

        page_btns.append (prev_btn);
        page_btns.append (next_btn);

        zoom_out_btn = new Gtk.Button.from_icon_name("zoom-out-symbolic") {
            css_classes = {"circular", "osd"},
            tooltip_text = _("Zoom Out")
        };

        zoom_in_btn = new Gtk.Button.from_icon_name("zoom-in-symbolic") {
            css_classes = {"circular", "osd"},
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
                media_buttons.margin_bottom = 40;
                zoom_btns.visible = false;
            } else {
                media_buttons.margin_bottom = 18;
                zoom_btns.visible = true;
            }

            on_zoom_change ();
        });

        zoom_changed.connect (on_zoom_change);

        zoom_btns.append (zoom_out_btn);
        zoom_btns.append (zoom_in_btn);

        media_buttons.append (page_btns);
        media_buttons.append (zoom_btns);

        return media_buttons;
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
        if (items.size > pos) return items.get(pos);

        return null;
    }
}
