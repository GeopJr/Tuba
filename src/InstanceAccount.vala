using GLib;
using Gee;

public class Tootle.InstanceAccount : API.Account, IStreamListener {

    public string instance { get; set; }
    public string client_id { get; set; }
    public string client_secret { get; set; }
    public string token { get; set; }

    public int64 last_seen_notification { get; set; default = 0; }
    public bool has_unread_notifications { get; set; default = false; }
    public ArrayList<API.Notification> cached_notifications { get; set; default = new ArrayList<API.Notification> (); }

	protected string? stream;

    public string handle {
        owned get { return @"@$username@$short_instance"; }
    }
    public string short_instance {
        owned get {
            return instance
                .replace ("https://", "")
                .replace ("/","");
        }
    }

    public InstanceAccount (Json.Object obj) {
        Object (
            username: obj.get_string_member ("username"),
            instance: obj.get_string_member ("instance"),
            client_id: obj.get_string_member ("id"),
            client_secret: obj.get_string_member ("secret"),
            token: obj.get_string_member ("access_token"),
            last_seen_notification: obj.get_int_member ("last_seen_notification"),
            has_unread_notifications: obj.get_boolean_member ("has_unread_notifications")
        );

        var cached = obj.get_object_member ("cached_profile");
    	var account = new API.Account (cached);
        patch (account);

        var notifications = obj.get_array_member ("cached_notifications");
        notifications.foreach_element ((arr, i, node) => {
            var notification = new API.Notification (node.get_object ());
            cached_notifications.add (notification);
        });
    }
	~InstanceAccount () {
		unsubscribe ();
	}

    public InstanceAccount.empty (string instance){
        Object (id: 0, instance: instance);
    }

    public InstanceAccount.from_account (API.Account account) {
        Object (id: account.id);
        patch (account);
    }

	public InstanceAccount patch (API.Account account) {
	    Utils.merge (this, account);
	    return this;
	}

    public bool is_current () {
    	return accounts.active.token == token;
    }

    public string get_stream_url () {
        return @"$instance/api/v1/streaming/?stream=user&access_token=$token";
    }

    public void subscribe () {
        streams.subscribe (get_stream_url (), this, out stream);
    }

    public void unsubscribe () {
        streams.unsubscribe (stream, this);
    }

    public override Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("hash");
        builder.add_string_value ("test");
        builder.set_member_name ("username");
        builder.add_string_value (username);
        builder.set_member_name ("instance");
        builder.add_string_value (instance);
        builder.set_member_name ("id");
        builder.add_string_value (client_id);
        builder.set_member_name ("secret");
        builder.add_string_value (client_secret);
        builder.set_member_name ("access_token");
        builder.add_string_value (token);
        builder.set_member_name ("last_seen_notification");
        builder.add_int_value (last_seen_notification);
        builder.set_member_name ("has_unread_notifications");
        builder.add_boolean_value (has_unread_notifications);

        var cached_profile = base.serialize ();
        builder.set_member_name ("cached_profile");
        builder.add_value (cached_profile);

        builder.set_member_name ("cached_notifications");
        builder.begin_array ();
        cached_notifications.@foreach (notification => {
            var node = notification.serialize ();
            if (node != null)
                builder.add_value (node);
            return true;
        });
        builder.end_array ();

        builder.end_object ();
        return builder.get_root ();
    }

    public override void on_notification (API.Notification obj) {
        var title = Html.remove_tags (obj.kind.get_desc (obj.account));
        var notification = new GLib.Notification (title);
        if (obj.status != null) {
            var body = "";
            body += short_instance;
            body += "\n";
            body += Html.remove_tags (obj.status.content);
            notification.set_body (body);
        }

        if (settings.notifications)
            app.send_notification (app.application_id + ":" + obj.id.to_string (), notification);

        if (is_current ())
            streams.notification (obj);

        if (obj.kind == API.NotificationType.WATCHLIST) {
            cached_notifications.add (obj);
            accounts.save ();
        }
    }

    public override void on_status_removed (int64 id) {
        if (is_current ())
            streams.status_removed (id);
    }

    public override void on_status_added (API.Status status) {
        if (!is_current ())
            return;

        // watchlist.users.@foreach (item => {
        // 	var acct = status.account.acct;
        //     if (item == acct || item == "@" + acct) {
        //         var obj = new API.Notification (-1);
        //         obj.kind = API.NotificationType.WATCHLIST;
        //         obj.account = status.account;
        //         obj.status = status;
        //         on_notification (obj);
        //     }
        //     return true;
        // });
    }

}
