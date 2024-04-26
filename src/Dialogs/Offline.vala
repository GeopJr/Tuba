public class Tuba.Dialogs.Offline : Adw.Window {
	construct {
		if (network_monitor.network_available || app.is_online) return;
		this.modal = true;

		this.default_height = this.default_width = 360;
		var toolbar_view = new Adw.ToolbarView () {
			extend_content_to_top_edge = true,
			content = new Adw.StatusPage () {
				icon_name = "network-wireless-offline-symbolic",
				title = _("Offline"),
				//  description = _("") // ???
			}
		};

		toolbar_view.add_top_bar (new Adw.HeaderBar () {
			show_title = false
		});

		this.content = toolbar_view;

		present ();
		app.notify["is-online"].connect (on_network_change);
	}

	public override bool close_request () {
		if (!app.is_online) {
			app.quit ();
		}
		return base.close_request ();
	}

	void on_network_change () {
		if (app.is_online) {
			close_request ();
		}
	}
}
