public class Tuba.Dialogs.Offline : Adw.Window {
	public Offline (Gtk.Window win) {
		if (network_monitor.network_available || app.is_online) return;
		this.transient_for = win;
		this.modal = true;
		this.resizable = false;
		this.default_height = 382;
		this.default_width = 360;

		var exit_btn = new Gtk.Button.with_label (_("Quit")) {
			css_classes = {"pill"},
			halign = Gtk.Align.CENTER
		};
		exit_btn.clicked.connect (on_quit);

		this.content = new Gtk.WindowHandle () {
			child = new Adw.StatusPage () {
				icon_name = "network-wireless-offline-symbolic",
				title = _("Offline"),
				description = _("No Network Connection"),
				child = exit_btn
			}
		};

		present ();
		app.notify["is-online"].connect (on_network_change);
	}

	public override bool close_request () {
		if (!app.is_online) {
			app.quit ();
		}
		return base.close_request ();
	}

	void on_quit () {
		this.close ();
	}

	void on_network_change () {
		if (app.is_online) {
			this.close ();
		}
	}
}
