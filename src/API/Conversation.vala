public class Tuba.API.Conversation : Entity, Widgetizable {

	public string id { get; set; }
	public Gee.ArrayList<API.Account>? accounts { get; set; }
	public bool unread { get; set; default = false; }
	public API.Status? last_status { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "accounts":
				return typeof (API.Account);
		}

		return base.deserialize_array_type (prop);
	}

	public override Gtk.Widget to_widget () {
		if (last_status == null) {
			var account_list = "";
			if (accounts != null) {
				foreach (var account in accounts) {
					account_list += @"<a href='$(account.url)'>$(account.handle)</a>, ";
				}
				account_list = account_list.slice (0, -2);
			} else {
				account_list = @"<a href='$(Tuba.accounts.active.url)'>$(Tuba.accounts.active.handle)</a>";
			}

			// translators: the variable is a comma separated list of account handles,
			//				this is a state - not an action
			return new Widgets.RichLabel (_("Empty Conversation with %s").printf (account_list)) {
				margin_top = 16,
				margin_bottom = 16,
				margin_start = 16,
				margin_end = 16
			};
		}
		return new Widgets.Conversation (this);
	}

	public override void open () {
		if (last_status == null) return;

		var view = new Views.Thread (last_status.formal);
		app.main_window.open_view (view);

		if (unread)
			mark_read ();
	}

	public void mark_read () {
		new Request.POST (@"/api/v1/conversations/$id/read")
			.with_account (Tuba.accounts.active)
			.then (() => {
				unread = false;
			})
			.exec ();
	}

}
