using Gtk;

public class Tuba.Widgets.Attachment.Item : Adw.Bin {

	public API.Attachment entity { get; set; default = null; }
	protected GestureClick gesture_click_controller { get; set; }
	protected GestureLongPress gesture_lp_controller { get; set; }
	protected PopoverMenu context_menu { get; set; }
	private const GLib.ActionEntry[] action_entries = {
		{"copy-url",        copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as",         save_as},
	};
	private GLib.SimpleActionGroup actions;

	protected Overlay overlay;
	protected Button button;
	protected Button alt_btn;
	protected Gtk.Box badge_box;
	protected ulong alt_btn_clicked_id;
	protected string media_kind;

	private void copy_url () {
		Host.copy (entity.url);
	}

	private void open_in_browser () {
		Host.open_uri (entity.url);
	}

	private void save_as () {
		save_media_as(entity.url);
	}

	public static void save_media_as (string url) {
		#if GTK_4_10
			var chooser = new FileDialog () {
				title = _("Save Attachment"),
				modal = true,
				initial_name = Path.get_basename (url)
			};

			chooser.save.begin (app.main_window, null, (obj, res) => {
				try {
					var file = chooser.save.end (res);
					if (file != null) {
		#else
			var chooser = new FileChooserNative (_("Save Attachment"), app.main_window, Gtk.FileChooserAction.SAVE, null, null);
			chooser.set_current_name(Path.get_basename (url));
			chooser.response.connect (id => {
				switch (id) {
					case ResponseType.ACCEPT:
						var file = chooser.get_file ();
		#endif
						message (@"Downloading file: $(url)...");
						download.begin(url, file, (obj, res) => {
							download.end (res);
						});
		#if GTK_4_10
					}
				} catch (Error e) {
					// User dismissing the dialog also ends here so don't make it sound like
					// it's an error
					warning (@"Couldn't get the result of FileDialog for attachment: $(e.message)");
				}
			});
		#else
						break;
				}
				chooser.unref ();
			});
			chooser.ref ();
			chooser.show ();
		#endif
	}

	private static async void download(string attachment_url, File file) {
		try {
			var req = yield new Request.GET (attachment_url).await ();
			var data = req.response_body;
			FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
			try {
				stream.splice (data, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);

				message (@"   OK: File written to: $(file.get_path ())");
			} catch (GLib.IOError e) {
				warning (e.message);
				//  app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
		} catch (GLib.Error e) {
			warning (e.message);
			//  app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
		}
	}

	construct {
		height_request = 164;

		actions = new GLib.SimpleActionGroup ();
		actions.add_action_entries (action_entries, this);
		this.insert_action_group ("attachment", actions);

		notify["entity"].connect (on_rebind);
		add_css_class ("flat");

		button = new Button ();
		button.overflow = Overflow.HIDDEN;
		button.clicked.connect (on_click);
		button.add_css_class ("frame");

		create_context_menu();
		gesture_click_controller = new GestureClick();
		gesture_lp_controller = new GestureLongPress();
        add_controller(gesture_click_controller);
        add_controller(gesture_lp_controller);
		gesture_click_controller.button = Gdk.BUTTON_SECONDARY;
		gesture_lp_controller.button = Gdk.BUTTON_PRIMARY;
		gesture_lp_controller.touch_only = true;
        gesture_click_controller.pressed.connect(on_secondary_click);
        gesture_lp_controller.pressed.connect(on_secondary_click);

		badge_box = new Gtk.Box(Orientation.HORIZONTAL, 1) {
			valign = Align.END,
			halign = Align.START
		};

		alt_btn = new Button.with_label("ALT") {
			tooltip_text = _("View Alt Text")
		};
		alt_btn.add_css_class ("heading");
		alt_btn.add_css_class ("flat");

		alt_btn_clicked_id = alt_btn.clicked.connect(() => {
			if (entity != null && entity.description != null)
				create_alt_text_window(entity.description, true);
		});

		badge_box.append(alt_btn);
		badge_box.add_css_class ("linked");
		badge_box.add_css_class ("ttl-status-badge");

		overlay = new Overlay ();
		overlay.child = button;
		overlay.add_overlay (badge_box);

		child = overlay;
		child.add_css_class ("attachment");
	}
	~Item () {
		message ("Destroying Attachment.Item widget");
		context_menu.unparent ();
	}

	protected Adw.Window create_alt_text_window (string alt_text, bool show = false) {
		var alt_label = new Label(alt_text) {
			wrap = true
		};

		var clamp = new Adw.Clamp () {
			child = alt_label,
			tightening_threshold = 100,
			valign = Align.START
		};

		var scrolledwindow = new ScrolledWindow() {
			child = clamp,
			vexpand = true,
			hexpand = true
		};

		var box = new Gtk.Box(Orientation.VERTICAL, 6);
		var headerbar = new Adw.HeaderBar();
		var window = new Adw.Window() {
			modal = true,
			title = @"Alternative text for $media_kind",
			transient_for = app.main_window,
			content = box,
			default_width = 400,
			default_height = 300
		};

		box.append(headerbar);
		box.append(scrolledwindow);

		if (show) window.show();
		alt_label.selectable = true;

		return window;
	}

	protected void create_context_menu() {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "attachment.open-in-browser");
		menu_model.append (_("Copy URL"), "attachment.copy-url");
		menu_model.append (_("Save Media"), "attachment.save-as");

		context_menu = new PopoverMenu.from_model(menu_model);
		context_menu.set_parent(this);
	}

	protected virtual void on_rebind () {
		alt_btn.visible = entity != null && entity.description != null && entity.description != "";
		media_kind = entity.kind.up();
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

	protected virtual void on_secondary_click () {
		gesture_click_controller.set_state(EventSequenceState.CLAIMED);
		gesture_lp_controller.set_state(EventSequenceState.CLAIMED);

		if (app.main_window.is_media_viewer_visible()) return;
		context_menu.popup();
	}

	protected async void open () throws Error {
		var path = yield Host.download (entity.url);
		Host.open_uri (path);
	}
}
