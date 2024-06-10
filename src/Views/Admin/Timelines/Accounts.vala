public class Tuba.Views.Admin.Timeline.Accounts : Views.Admin.Timeline.PaginationTimeline {
	public signal void on_open_account (API.Admin.Account account);

	~Accounts () {
		debug ("Destroying Accounts");
	}

	construct {
		this.url = "/api/v1/admin/accounts";
		this.accepts = typeof (API.Admin.Account);
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		Gtk.Widget widget = base.on_create_model_widget (obj);
		var action_row = widget as Widgets.Admin.AccountRow;
		if (action_row != null) {
			action_row.account_opened.connect (on_account_opened);
		}

		return widget;
	}

	private void on_account_opened (API.Admin.Account account) {
		on_open_account (account);
	}
}
