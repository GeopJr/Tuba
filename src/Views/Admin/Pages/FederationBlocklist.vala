public class Tuba.Views.Admin.Page.FederationBlockList : Views.Admin.Page.Base {
	Views.Admin.Timeline.DomainBlock pagination_timeline;
	construct {
		// translators: Admin Dialog page title,
		//				this is about federation blocking
		this.title = _("Federation Blocklist");

		var add_ip_block_button = new Gtk.Button.from_icon_name ("tuba-plus-large-symbolic") {
			tooltip_text = _("Add Federation Block"),
			css_classes = {"flat"}
		};
		add_ip_block_button.clicked.connect (open_add_federation_block_dialog);
		headerbar.pack_end (add_ip_block_button);

		pagination_timeline = new Views.Admin.Timeline.DomainBlock ();
		pagination_timeline.on_error.connect (on_error);
		pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
		this.page = pagination_timeline;

		refresh ();
	}

	private void open_add_federation_block_dialog () {
		if (this.admin_window == null) return;
		var add_federation_block_dialog = new Dialogs.Admin.AddFederationBlock ();
		add_federation_block_dialog.added.connect (refresh);
		add_federation_block_dialog.present (this.admin_window);
	}

	private void refresh () {
		pagination_timeline.request_idle ();
	}
}
