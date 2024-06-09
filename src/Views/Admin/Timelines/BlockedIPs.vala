public class Tuba.Views.Admin.Timeline.BlockedIPs : Views.Admin.Timeline.PaginationTimeline {
	~BlockedIPs () {
		debug ("Destroying BlockedIPs");
	}

	construct {
		this.url = "/api/v1/admin/ip_blocks";
		this.accepts = typeof (API.Admin.DomainBlock);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		Gtk.Widget widget = base.on_create_model_widget (obj);
		var action_row = widget as Widgets.Admin.IPBlock;
		if (action_row != null) {
			action_row.removed.connect (on_remove);
		}

		return widget;
	}

	private void on_remove (Widgets.Admin.IPBlock widget, string ip_block_id) {
		var dlg = new Adw.AlertDialog (
			// tranlsators: Question dialog when an admin is about to
			//				unblock an IP address. The variable
			//				is a string IP address
			_("Are you sure you want to unblock %s?").printf (widget.title),
			null
		);

		dlg.add_response ("no", _("Cancel"));
		dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("yes", _("Unblock"));
		dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
		dlg.choose.begin (this, null, (obj, res) => {
			if (dlg.choose.end (res) == "yes") {
				widget.sensitive = false;
				new Request.DELETE (@"/api/v1/admin/ip_blocks/$ip_block_id")
					.with_account (accounts.active)
					.then (() => {
						widget.sensitive = true;
						request_idle ();
					})
					.on_error ((code, message) => {
						widget.sensitive = true;
						on_error (code, message);
					})
					.exec ();
			}
		});
	}
}
