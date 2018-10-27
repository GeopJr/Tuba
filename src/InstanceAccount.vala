public class Tootle.InstanceAccount : GLib.Object {

    public string username {get; set;}
    public string instance {get; set;}
    public string client_id {get; set;}
    public string client_secret {get; set;}
    public string token {get; set;}

    private Notificator? notificator;

    public InstanceAccount () {}
    
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
        return acc;
    }
    
    public void notification (Notification obj) {
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
        
        if (accounts.formal.token == this.token)
            network.notification (obj);
    }
    
    private void status_removed (int64 id) {
        if (accounts.formal.token == this.token)
            network.status_removed (id);
    }
    
    private void status_added (Status status) {
        if (accounts.formal.token != this.token)
            return;
        
        var acct = status.account.acct;
        var obj = new Notification (-1);
        obj.type = NotificationType.WATCHLIST;
        obj.account = status.account;
        obj.status = status;
        watchlist.users.@foreach (item => {
            if (item == acct || item == "@" + acct)
                notification (obj);
            return true;
        });
    }

}
