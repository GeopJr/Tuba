public class Tootle.API.Notification : GLib.Object, Widgetizable {

    public int64 id { get; construct set; }
    public Account account { get; construct set; }

    public NotificationType kind { get; set; }
    public string created_at { get; set; }
    public Status? status { get; set; default = null; }

    public Notification (Json.Object obj) throws Oopsie {
        Object (
            id: int64.parse (obj.get_string_member ("id")),
            kind: NotificationType.from_string (obj.get_string_member ("type")),
            created_at: obj.get_string_member ("created_at"),
            account: new Account (obj.get_object_member ("account"))
        );

        if (obj.has_member ("status"))
            status = new Status (obj.get_object_member ("status"));
    }

    public Notification.follow_request (Json.Object obj) {
        Object (
            id: 0,
            kind: NotificationType.FOLLOW_REQUEST,
            account: new Account (obj)
        );
    }

    public override Gtk.Widget to_widget () {
        return new Widgets.Notification (this);
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("type");
        builder.add_string_value (kind.to_string ());
        builder.set_member_name ("created_at");
        builder.add_string_value (created_at);

        if (status != null) {
            builder.set_member_name ("status");
            builder.add_value (status.serialize ());
        }
        if (account != null) {
            builder.set_member_name ("account");
            builder.add_value (account.serialize ());
        }

        builder.end_object ();
        return builder.get_root ();
    }

    public Soup.Message? dismiss () {
        if (kind == NotificationType.WATCHLIST) {
            if (accounts.active.cached_notifications.remove (this))
                accounts.save ();
            return null;
        }

        if (kind == NotificationType.FOLLOW_REQUEST)
            return reject_follow_request ();

		var req = new Request.POST ("/api/v1/notifications/dismiss")
		    .with_account (accounts.active)
			.with_param ("id", id.to_string ())
			.exec ();
        return req;
    }

    public Soup.Message accept_follow_request () {
        var req = new Request.POST (@"/api/v1/follow_requests/$(account.id)/authorize")
            .with_account (accounts.active)
            .exec ();
        return req;
    }

    public Soup.Message reject_follow_request () {
        var req = new Request.POST (@"/api/v1/follow_requests/$(account.id)/reject")
            .with_account (accounts.active)
            .exec ();
        return req;
    }

}
