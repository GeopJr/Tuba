public class Tuba.Views.Admin.Timeline.EmailDomain : Views.Admin.Timeline.PaginationTimeline {
	~EmailDomain () {
		debug ("Destroying EmailDomain");
	}

	construct {
		this.url = "/api/v1/admin/email_domain_blocks";
		this.accepts = typeof (API.Admin.EmailDomainBlock);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		Gtk.Widget widget = base.on_create_model_widget (obj);
		var action_row = widget as Widgets.Admin.EmailDomainBlock;
		if (action_row != null) {
			action_row.removed.connect (on_remove);
		}

		return widget;
	}

	private void on_remove (Widgets.Admin.EmailDomainBlock widget, string domain_block_id) {
		var dlg = new Adw.AlertDialog (
			// translators: Question dialog when an admin is about to
			//				unblock an e-mail address block. The variable
			//				is a string e-mail address
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
				new Request.DELETE (@"/api/v1/admin/email_domain_blocks/$domain_block_id")
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
