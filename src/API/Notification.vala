public class Tuba.API.Notification : Entity, Widgetizable {

    public string id { get; set; }
    public API.Account account { get; set; }
    public string? kind { get; set; default = null; }
    public API.Status? status { get; set; default = null; }

    public override void open () {
        if (status != null) {
            status.open ();
        } else {
            account.open ();
        }
    }

    public override Gtk.Widget to_widget () {
        return new Widgets.Notification (this);
    }

	// TODO: notification actions
	public virtual GLib.Notification to_toast (InstanceAccount issuer, int others = 0) {
        Tuba.InstanceAccount.Kind res_kind;

        var kind_actor_name = account.display_name;
        if (others > 0) {
            kind_actor_name = _("%s & %d others").printf (account.display_name, others);
        }

		issuer.describe_kind (kind, out res_kind, kind_actor_name);

		var toast = new GLib.Notification ( HtmlUtils.remove_tags (res_kind.description) );
		if (status != null) {
			var body = "";
			body += HtmlUtils.remove_tags (status.content);
			toast.set_body (body);
		}

        if (!Tuba.is_flatpak) {
            var icon_file = GLib.File.new_for_uri (account.avatar);
            var icon = new FileIcon (icon_file);
            toast.set_icon (icon);
        }

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
