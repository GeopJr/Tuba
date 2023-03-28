public class Tuba.API.Notification : Entity, Widgetizable {

    public string id { get; set; }
    public API.Account account { get; set; }
    public string? kind { get; set; default = null; }
    public API.Status? status { get; set; default = null; }

    public override Gtk.Widget to_widget () {
        return new Widgets.Notification (this);
    }

	// TODO: notification actions
	public virtual GLib.Notification to_toast (InstanceAccount issuer) {
		string descr;
		string descr_url;
		issuer.describe_kind (kind, null, out descr, account, out descr_url);

		var toast = new GLib.Notification ( HtmlUtils.remove_tags (descr) );
		if (status != null) {
			var body = "";
			body += HtmlUtils.remove_tags (status.content);
			toast.set_body (body);
		}

		var icon_file = GLib.File.new_for_uri (account.avatar);
		var icon = new FileIcon (icon_file);
		toast.set_icon (icon);

		// toast.add_button_with_target_value (_("Read"), "mastodon.read_notification", id);

		return toast;
	}

    // public Soup.Message accept_follow_request () {
    //     var req = new Request.POST (@"/api/v1/follow_requests/$(account.id)/authorize")
    //         .with_account (accounts.active)
    //         .exec ();
    //     return req;
    // }

    // public Soup.Message reject_follow_request () {
    //     var req = new Request.POST (@"/api/v1/follow_requests/$(account.id)/reject")
    //         .with_account (accounts.active)
    //         .exec ();
    //     return req;
    // }

}
