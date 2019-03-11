using GLib;
using Gee;

public class Tootle.InstanceAccount : Object {

    public string username {get; set;}
    public string instance {get; set;}
    public string client_id {get; set;}
    public string client_secret {get; set;}
    public string token {get; set;}

    public int64 last_seen_notification {get; set; default = 0;}
    public bool has_unread_notifications {get; set; default = false;}
    public ArrayList<API.Notification> cached_notifications {get; set;}

    private Notificator? notificator;

    public InstanceAccount () {
        cached_notifications = new ArrayList<API.Notification> ();
    }

    public string get_pretty_instance () {
        return instance
            .replace ("https://", "")
            .replace ("/","");
    }

    public void start_notificator () {
        if (notificator != null)
            notificator.close ();

        notificator = new Notificator (get_stream ());
        notificator.status_added.connect (status_added);
        notificator.status_removed.connect (status_removed);
        notificator.notification.connect (notification);
        notificator.start ();
    }

    public bool is_current () {
    	return accounts.formal.token == token;
    }

    public Soup.Message get_stream () {
        var url = "%s/api/v1/streaming/?stream=user&access_token=%s".printf (instance, token);
        return new Soup.Message ("GET", url);
    }

    public void close_notificator () {
        if (notificator != null)
            notificator.close ();
    }

    public Json.Node serialize () {
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
        builder.set_member_name ("token");
        builder.add_string_value (token);
        builder.set_member_name ("last_seen_notification");
        builder.add_int_value (last_seen_notification);
        builder.set_member_name ("has_unread_notifications");
        builder.add_boolean_value (has_unread_notifications);

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

    public static InstanceAccount parse (Json.Object obj) {
        var acc = new InstanceAccount ();
        acc.username = obj.get_string_member ("username");
        acc.instance = obj.get_string_member ("instance");
        acc.client_id = obj.get_string_member ("id");
        acc.client_secret = obj.get_string_member ("secret");
        acc.token = obj.get_string_member ("token");
        acc.last_seen_notification = obj.get_int_member ("last_seen_notification");
        acc.has_unread_notifications = obj.get_boolean_member ("has_unread_notifications");

        var notifications = obj.get_array_member ("cached_notifications");
        notifications.foreach_element ((arr, i, node) => {
            var notification = API.Notification.parse (node.get_object ());
            acc.cached_notifications.add (notification);
        });

        return acc;
    }

    public void notification (API.Notification obj) {
        var title = Html.remove_tags (obj.type.get_desc (obj.account));
        var notification = new GLib.Notification (title);
        if (obj.status != null) {
            var body = "";
            body += get_pretty_instance ();
            body += "\n";
            body += Html.remove_tags (obj.status.content);
            notification.set_body (body);
        }

        if (settings.notifications)
            app.send_notification (app.application_id + ":" + obj.id.to_string (), notification);

        if (is_current ())
            network.notification (obj);

        if (obj.type == API.NotificationType.WATCHLIST) {
            cached_notifications.add (obj);
            accounts.save ();
        }
    }

    private void status_removed (int64 id) {
        if (is_current ())
            network.status_removed (id);
    }

    private void status_added (API.Status status) {
        if (!is_current ())
            return;

        watchlist.users.@foreach (item => {
        	var acct = status.account.acct;
            if (item == acct || item == "@" + acct) {
                var obj = new API.Notification (-1);
                obj.type = API.NotificationType.WATCHLIST;
                obj.account = status.account;
                obj.status = status;
                notification (obj);
            }
            return true;
        });
    }

}
