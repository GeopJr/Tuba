public class Tuba.Views.MediaViewer : Gtk.Box {
    public class Item : Adw.Bin {
        private Gtk.Stack stack;
        private Gtk.Overlay overlay;
        private Gtk.Spinner spinner;
        public string url { get; private set; }

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

        public Item (Gtk.Widget child, string t_url, Gdk.Paintable? paintable) {
            stack.add_named (child, "child");
            this.url = t_url;

            if (paintable != null) overlay.child = new Gtk.Picture.for_paintable (paintable);
        }

        public void done () {
            spinner.spinning = false;
            stack.visible_child_name = "child";
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

    private Item[] items;
	protected Gtk.Button fullscreen_btn;
	protected Adw.HeaderBar headerbar;
    protected ImageCache image_cache;
    private Adw.Carousel carousel;

	construct {
        carousel = new Adw.Carousel () {
            vexpand = true,
            hexpand = true,
            css_classes = {"osd"}
        };
        image_cache = new ImageCache () {
            maintenance_secs = 60 * 5
        };

        var drag = new Gtk.GestureDrag ();
        drag.drag_end.connect(on_drag_end);
        add_controller (drag);

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

        append(headerbar);
        append(carousel);

		setup_mouse_previous_click();
	}
	~MediaViewer () {
		message ("Destroying MediaViewer");
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
		Host.copy (items[(int) carousel.position].url);
	}

	private void open_in_browser () {
		Host.open_uri (items[(int) carousel.position].url);
	}

	private void save_as () {
		Widgets.Attachment.Item.save_media_as(items[(int) carousel.position].url);
	}

    private void on_drag_end (double x, double y) {
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
		foreach (var item in items) {
            carousel.remove (item);
        }
        items = {};
    }

    private async string download_video (string url) throws Error {
		return yield Host.download (url);
	}

    public void add_video (string url, Gdk.Paintable? preview, int? pos) {
        var video = new Gtk.Video ();
        var item = new Item (video, url, preview);
        if (pos == null) {
            carousel.append (item);
        } else {
            carousel.insert(item, pos);
        }
        items += item;

		download_video.begin (url, (obj, res) => {
			try {
				var path = download_video.end (res);
                video.set_filename(path);
                item.done ();
			}
			catch (Error e) {
				app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
		});
	}

    public void add_image(string url, string? alt_text, Gdk.Paintable? preview, int? pos) {
        var picture = new Gtk.Picture ();
        var item = new Item (picture, url, preview);
        if (pos == null) {
            carousel.append (item);
        } else {
            carousel.insert(item, pos);
        }
        items += item;

        if (alt_text != null) picture.alternative_text = alt_text;

		image_cache.request_paintable (url, (is_loaded, data) => {
            picture.paintable = data;
            if (is_loaded) {
                item.done ();
            }
        });
    }

    public void scroll_to (int pos) {
        if (pos >= items.length) return;

        // https://gitlab.gnome.org/GNOME/libadwaita/-/issues/597
        // https://gitlab.gnome.org/GNOME/libadwaita/-/merge_requests/827
        uint timeout = 0;
		timeout = Timeout.add (1000, () => {
            carousel.scroll_to(carousel.get_nth_page(pos), true);
			GLib.Source.remove(timeout);

			return true;
		}, Priority.LOW);
    }
}
