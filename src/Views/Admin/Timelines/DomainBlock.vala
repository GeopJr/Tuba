public class Tuba.Views.Admin.Timeline.DomainBlock : Views.Admin.Timeline.PaginationTimeline {
	~DomainBlock () {
		debug ("Destroying DomainBlock");
	}

	construct {
		this.url = "/api/v1/admin/domain_blocks";
		this.accepts = typeof (API.Admin.DomainBlock);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		Gtk.Widget widget = base.on_create_model_widget (obj);
		var action_row = widget as Widgets.Admin.DomainBlock;
		if (action_row != null) {
			action_row.removed.connect (on_remove);
		}

		return widget;
	}

	private void on_remove (Widgets.Admin.DomainBlock widget, string federation_block_id) {
		on_remove_real.begin (widget, federation_block_id);
	}

	private async void on_remove_real (Widgets.Admin.DomainBlock widget, string federation_block_id) {
		var dlg = new Adw.AlertDialog (
			// translators: Question dialog when an admin is about to
			//				delete a federation block. The variable is
			//				a string domain name
			_("Unblock %s?").printf (widget.title),
			null
		);

		dlg.add_response ("no", _("Cancel"));
		dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("yes", _("Unblock"));
		dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);

		if ((yield dlg.choose (this, null)) == "yes") {
				widget.sensitive = false;
				var req = new RequestV2 (@"/api/v1/admin/domain_blocks/$federation_block_id", DELETE) { account = accounts.active };
				try {
					yield req.exec (null);
					widget.sensitive = true;
					yield request ();
				} catch (Error e) {
					widget.sensitive = true;
					on_error (e.code, e.message);
				}
		}
	}
}
