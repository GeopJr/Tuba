public class Tuba.Views.Admin.Timeline.DomainAllow : Views.Admin.Timeline.PaginationTimeline {
	~DomainAllow () {
		debug ("Destroying DomainAllow");
	}

	construct {
		this.url = "/api/v1/admin/domain_allows";
		this.accepts = typeof (API.Admin.DomainAllow);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		Gtk.Widget widget = base.on_create_model_widget (obj);
		var action_row = widget as Widgets.Admin.DomainAllow;
		if (action_row != null) {
			action_row.removed.connect (on_remove);
		}

		return widget;
	}

	private void on_remove (Widgets.Admin.DomainAllow widget, string domain_allow_id) {
		on_remove_real.begin (widget, domain_allow_id);
	}

	private async void on_remove_real (Widgets.Admin.DomainAllow widget, string domain_allow_id) {
		var dlg = new Adw.AlertDialog (
			// translators: Question dialog when an admin is about to
			//				delete a domain from the federation allowlist.
			//				You can replace 'federation' with 'communication' if
			//				it's hard to translate.
			//				The variable is a string domain name
			_("Remove Federation with %s?").printf (widget.title),
			null
		);

		dlg.add_response ("no", _("Cancel"));
		dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("yes", _("Remove"));
		dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);

		if ((yield dlg.choose (this, null)) == "yes") {
				widget.sensitive = false;
				var req = new RequestV2 (@"/api/v1/admin/domain_allows/$domain_allow_id", DELETE) { account = accounts.active };
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
