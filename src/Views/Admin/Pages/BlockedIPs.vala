public class Tuba.Views.Admin.Page.BlockedIPs : Views.Admin.Page.Base {
	Views.Admin.Timeline.BlockedIPs pagination_timeline;
	construct {
		// translators: Admin Dialog page title,
		//				this is about blocking
		//				IP Addresses
		this.title = _("IP Rules");

		var add_ip_block_button = new Gtk.Button.from_icon_name ("tuba-plus-large-symbolic") {
			tooltip_text = _("Add IP Block"),
			css_classes = {"flat"}
		};
		add_ip_block_button.clicked.connect (open_add_ip_block_dialog);
		headerbar.pack_end (add_ip_block_button);

		pagination_timeline = new Views.Admin.Timeline.BlockedIPs ();
		pagination_timeline.on_error.connect (on_error);
		pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
		this.page = pagination_timeline;

		refresh ();
	}

	private void open_add_ip_block_dialog () {
		if (this.admin_window == null) return;
		var add_ip_block_dialog = new Dialogs.Admin.AddIPBlock ();
		add_ip_block_dialog.added.connect (refresh);
		add_ip_block_dialog.present (this.admin_window);
	}

	private void refresh () {
		pagination_timeline.request_idle ();
	}
}
