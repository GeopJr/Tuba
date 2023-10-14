public class Tuba.Widgets.Attachment.Item : Adw.Bin {
	public API.Attachment entity { get; set; default = null; }
	protected Gtk.GestureClick gesture_click_controller { get; set; }
	protected Gtk.GestureLongPress gesture_lp_controller { get; set; }
	protected Gtk.PopoverMenu context_menu { get; set; }
	private const GLib.ActionEntry[] ACTION_ENTRIES = {
		{"copy-url", copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as", save_as},
	};
	private GLib.SimpleActionGroup actions;

	protected Gtk.Overlay overlay;
	protected Gtk.Button button;
	protected Gtk.Button alt_btn;
	protected Gtk.Box badge_box;
	protected ulong alt_btn_clicked_id;
	protected Tuba.Attachment.MediaType media_kind;

	private void copy_url () {
		Host.copy (entity.url);
	}

	private void open_in_browser () {
		Host.open_uri (entity.url);
	}

	private void save_as () {
		save_media_as (entity.url);
	}

	public static void save_media_as (string url) {
		var chooser = new Gtk.FileDialog () {
			title = _("Save Attachment"),
			modal = true,
			initial_name = Path.get_basename (url)
		};

		chooser.save.begin (app.main_window, null, (obj, res) => {
			try {
				var file = chooser.save.end (res);
				if (file != null) {
					debug (@"Downloading file: $(url)…");
					download.begin (url, file, (obj, res) => {
						download.end (res);
					});
				}
			} catch (Error e) {
				// User dismissing the dialog also ends here so don't make it sound like
				// it's an error
				warning (@"Couldn't get the result of FileDialog for attachment: $(e.message)");
			}
		});
	}

	private static async void download (string attachment_url, File file) {
		try {
			var req = yield new Request.GET (attachment_url).await ();
			var data = req.response_body;
			FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
			try {
				stream.splice (data, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);

				debug (@"   OK: File written to: $(file.get_path ())");
			} catch (GLib.IOError e) {
				warning (e.message);
				//  app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
		} catch (GLib.Error e) {
			warning (e.message);
			//  app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
		}
	}

	protected SimpleAction copy_media_simple_action;
	construct {
		height_request = 164;

		actions = new GLib.SimpleActionGroup ();
		actions.add_action_entries (ACTION_ENTRIES, this);

		copy_media_simple_action = new SimpleAction ("copy-media", null);
		copy_media_simple_action.activate.connect (copy_media);
		actions.add_action (copy_media_simple_action);

		this.insert_action_group ("attachment", actions);

		notify["entity"].connect (on_rebind);
		add_css_class ("flat");

		button = new Gtk.Button () {
			css_classes = { "frame" },
			overflow = Gtk.Overflow.HIDDEN
		};
		button.clicked.connect (on_click);

		create_context_menu ();
		gesture_click_controller = new Gtk.GestureClick ();
		gesture_lp_controller = new Gtk.GestureLongPress ();
        add_controller (gesture_click_controller);
        add_controller (gesture_lp_controller);
		gesture_click_controller.button = Gdk.BUTTON_SECONDARY;
		gesture_lp_controller.button = Gdk.BUTTON_PRIMARY;
		gesture_lp_controller.touch_only = true;
        gesture_click_controller.pressed.connect (on_secondary_click);
        gesture_lp_controller.pressed.connect (on_long_press);

		badge_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 1) {
			valign = Gtk.Align.END,
			halign = Gtk.Align.START,
			css_classes = { "linked", "ttl-status-badge" }
		};

		alt_btn = new Gtk.Button.with_label ("ALT") {
			tooltip_text = _("View Alt Text"),
			css_classes = { "heading", "flat" }
		};

		alt_btn_clicked_id = alt_btn.clicked.connect (on_alt_text_btn_clicked);

		badge_box.append (alt_btn);

		overlay = new Gtk.Overlay () {
			css_classes = { "attachment" }
		};
		overlay.child = button;
		overlay.add_overlay (badge_box);

		child = overlay;
	}
	~Item () {
		debug ("Destroying Attachment.Item widget");
		context_menu.unparent ();
	}

	private void on_alt_text_btn_clicked () {
		if (entity != null && entity.description != null)
			create_alt_text_window (entity.description, true);
	}

	protected Adw.Window create_alt_text_window (string alt_text, bool show = false) {
		var alt_label = new Gtk.Label (alt_text) {
			wrap = true
		};

		var clamp = new Adw.Clamp () {
			child = alt_label,
			tightening_threshold = 100,
			valign = Gtk.Align.START
		};

		var scrolledwindow = new Gtk.ScrolledWindow () {
			child = clamp,
			vexpand = true,
			hexpand = true,
			margin_bottom = 6,
			margin_top = 6
		};

		var toolbar_view = new Adw.ToolbarView ();
		var headerbar = new Adw.HeaderBar ();
		var window = new Adw.Window () {
			modal = true,
			title = _("Alternative text for attachment"),
			transient_for = app.main_window,
			content = toolbar_view,
			default_width = 400,
			default_height = 300
		};
		window.add_binding_action (Gdk.Key.Escape, 0, "window.close", null);

		toolbar_view.add_top_bar (headerbar);
		toolbar_view.set_content (scrolledwindow);

		if (show) window.show ();
		alt_label.selectable = true;

		return window;
	}

	protected void create_context_menu () {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "attachment.open-in-browser");
		menu_model.append (_("Copy URL"), "attachment.copy-url");
		menu_model.append (_("Save Media"), "attachment.save-as");

		var copy_media_menu_item = new MenuItem (_("Copy Media"), "attachment.copy-media");
		copy_media_menu_item.set_attribute_value ("hidden-when", "action-disabled");
		menu_model.append_item (copy_media_menu_item);

		context_menu = new Gtk.PopoverMenu.from_model (menu_model) {
			has_arrow = false,
			halign = Gtk.Align.START
		};
		context_menu.set_parent (this);
	}

	protected virtual void copy_media () {}

	protected virtual void on_rebind () {
		alt_btn.visible = entity != null && entity.description != null && entity.description != "";
		media_kind = Tuba.Attachment.MediaType.from_string (entity.kind);
	}

	protected virtual void on_click () {
		open.begin ((obj, res) => {
			try {
				open.end (res);
			}
			catch (Error e) {
				var dlg = app.inform (_("Error"), e.message);
				dlg.present ();
			}
		});
	}

	private void on_long_press (double x, double y) {
		on_secondary_click (1, x, y);
	}

	protected virtual void on_secondary_click (int n_press, double x, double y) {
		gesture_click_controller.set_state (Gtk.EventSequenceState.CLAIMED);
		gesture_lp_controller.set_state (Gtk.EventSequenceState.CLAIMED);

		if (app.main_window.is_media_viewer_visible) return;
		Gdk.Rectangle rectangle = {
			(int) x,
			(int) y,
			0,
			0
		};
		context_menu.set_pointing_to (rectangle);
		context_menu.popup ();
	}

	protected async void open () throws Error {
		var path = yield Host.download (entity.url);
		Host.open_uri (path);
	}
}
