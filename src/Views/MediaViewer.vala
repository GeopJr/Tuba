public class Tuba.Views.MediaViewer : Gtk.Box {
    // Keep track of the curret type
    // for switching between spinner
    // video and image
    private string _type = "image";
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
    public bool spinning {
		set {
            stack.visible_child_name = value ? "spinner" : _type;
        }
		get { return stack.visible_child_name == "spinner"; }
	}

    private const GLib.ActionEntry[] action_entries = {
		{"copy-url",        copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as",         save_as},
	};
    public string url { set; get; }

	protected Gtk.Stack stack;
	protected Gtk.Picture pic;
	protected Gtk.Video video;
	protected Gtk.Button fullscreen_btn;
	protected Adw.HeaderBar headerbar;
    protected ImageCache image_cache;
	public Gdk.Paintable paintable {
		set {
            _type = "image";
            this.pic.paintable = value;
        }
		get { return this.pic.paintable; }
	}
    public string? alternative_text {
		set { 
            _type = "image";
            this.pic.alternative_text = value;
        }
		get { return this.pic.alternative_text; }
	}

	construct {
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

        stack = new Gtk.Stack() {
			css_classes = {"osd"}
        };

        video = new Gtk.Video () {
			hexpand = true,
			vexpand = true,
            autoplay = true
		};
        stack.add_named(video, "video");

        pic = new Gtk.Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true
		};
        stack.add_named(pic, "image");

        var spinner = new Gtk.Spinner() {
			spinning = true,
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			vexpand = true,
			hexpand = true,
			width_request = 32,
			height_request = 32
		};
        stack.add_named(spinner, "spinner");

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
        append(stack);

        stack.visible_child_name = "spinner";
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

    public void set_video (string? url) {
        // Clear
        if (url == null) {
            video.file = null;
            video.set_filename(null);
            return;
        }

        _type = "video";
		download_video.begin (url, (obj, res) => {
			try {
				download_video.end (res);
			}
			catch (Error e) {
				app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
		});
	}

	private async void download_video (string url) throws Error {
		var path = yield Host.download (url);
        video.set_filename(path);
        stack.visible_child_name = "video";
	}

    protected GLib.Menu create_actions_menu() {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "mediaviewer.open-in-browser");
		menu_model.append (_("Copy URL"), "mediaviewer.copy-url");
		menu_model.append (_("Save Media"), "mediaviewer.save-as");

        return menu_model;
	}

    private void copy_url () {
		Host.copy (url);
	}

	private void open_in_browser () {
		Host.open_uri (url);
	}

	private void save_as () {
		Widgets.Attachment.Item.save_media_as(url);
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
		this.paintable = null;
		this.set_video(null);
		this.url = "";
		this.spinning = true;
    }

    private void on_media_viewer_cache_response(bool is_loaded, owned Gdk.Paintable? data) {
		this.paintable = data;
		if (is_loaded) {
			this.spinning = false;
		}
	}

    public void set_image(string url) {
		image_cache.request_paintable (url, on_media_viewer_cache_response);
    }
}
