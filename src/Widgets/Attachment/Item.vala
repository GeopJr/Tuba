using Gtk;

public class Tooth.Widgets.Attachment.Item : Adw.Bin {

	public API.Attachment entity { get; set; default = null; }
	protected GestureClick gesture_click_controller { get; set; }
	protected PopoverMenu context_menu { get; set; }
	private const GLib.ActionEntry[] action_entries = {
		{"copy-url",        copy_url},
		{"open-in-browser", open_in_browser},
		{"save-as",         save_as},
	};
	private GLib.SimpleActionGroup actions;

	protected Overlay overlay;
	protected Button button;
	protected Label badge;


	private void copy_url () {
		Host.copy (entity.url);
	}

	private void open_in_browser () {
		Host.open_uri (entity.url);
	}

	private void save_as () {
		var chooser = new FileChooserNative (_("Save Attachment"), app.main_window, Gtk.FileChooserAction.SAVE, null, null);
		chooser.set_current_name(Path.get_basename (entity.url));
		chooser.response.connect (id => {
			switch (id) {
				case ResponseType.ACCEPT:
					message (@"Downloading file: $(entity.url)...");
					download.begin(entity.url, chooser.get_file (), (obj, res) => {
						download.end (res);
					});
					break;
			}
			chooser.unref ();
		});
		chooser.ref ();
		chooser.show ();
	}

	private async void download(string attachment_url, File file) {
		try {
			var msg = yield new Request.GET (attachment_url).await ();
			var data = msg.response_body.data;
			FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
			try {
				stream.write (data);

				message (@"   OK: File written to: $(file.get_path ())");
			} catch (GLib.IOError e) {
				warning (e.message);
				app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
		} catch (GLib.Error e) {
			warning (e.message);
			app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
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
		button.clicked.connect (on_click);

		create_context_menu();
		gesture_click_controller = new GestureClick();
        add_controller(gesture_click_controller);
		gesture_click_controller.button = Gdk.BUTTON_SECONDARY;
        gesture_click_controller.pressed.connect(on_secondary_click);

		badge = new Label ("") {
			valign = Align.END,
			halign = Align.START
		};
		badge.add_css_class ("osd");
		badge.add_css_class ("heading");

		overlay = new Overlay ();
		overlay.child = button;
		overlay.add_overlay (badge);

		child = overlay;
		child.add_css_class ("attachment");
	}

	protected void create_context_menu() {
		var menu_model = new GLib.Menu ();
		menu_model.append (_("Open in Browser"), "attachment.open-in-browser");
		menu_model.append (_("Copy URL"), "attachment.copy-url");
		menu_model.append (_("Save as…"), "attachment.save-as");

		context_menu = new PopoverMenu.from_model(menu_model);
		context_menu.set_parent(this);
	}

	protected virtual void on_rebind () {
		button.tooltip_text = entity == null ? null : entity.description;
		badge.label = entity == null ? "" : entity.kind.up();
	}

	protected virtual void on_click () {
		open.begin ((obj, res) => {
			try {
				open.end (res);
			}
			catch (Error e) {
				app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
			}
		});
	}

	protected virtual void on_secondary_click () {
		gesture_click_controller.set_state(EventSequenceState.CLAIMED);
		context_menu.popup();
	}

	protected async void open () throws Error {
		var path = yield Host.download (entity.url);
		Host.open_uri (path);
	}

}
