public class Tootle.API.Conversation : Entity, Widgetizable {

	public string id { get; set; }
	public Gee.ArrayList<API.Account> accounts { get; set; }
	public bool unread { get; set; default = false; }
	public API.Status? last_status { get; set; default = null; }

    public override Gtk.Widget to_widget () {
        return new Widgets.Conversation (this);
    }

	public override void open () {
		var view = new Views.Thread (last_status.formal);
		app.main_window.open_view (view);

		if (unread)
			mark_read ();
	}

	public void mark_read () {
		new Request.POST (@"/api/v1/conversations/$id/read")
			.with_account (Tootle.accounts.active)
			.then (() => {
				unread = false;
			})
			.on_error (() => {})
			.exec ();
	}

}
