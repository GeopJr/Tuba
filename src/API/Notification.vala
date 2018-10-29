public class Tootle.Notification{

    public int64 id;
    public NotificationType type;
    public string created_at;
    
    public Status? status;
    public Account? account;

    public Notification (int64 _id) {
        id = _id;
    }

    public static Notification parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var notification = new Notification (id);
        
        notification.type = NotificationType.from_string (obj.get_string_member ("type"));
        notification.created_at = obj.get_string_member ("created_at");
        
        if (obj.has_member ("status"))
            notification.status = Status.parse (obj.get_object_member ("status"));
        if (obj.has_member ("account"))
            notification.account = Account.parse (obj.get_object_member ("account"));
        
        return notification;
    }
    
    public static Notification parse_follow_request (Json.Object obj) {
        var notification = new Notification (-1);
        var account = Account.parse (obj);
        
        notification.type = NotificationType.FOLLOW_REQUEST;
        notification.account = account;
        
        return notification;
    }
    
    public Soup.Message? dismiss () {
        if (type == NotificationType.WATCHLIST)
            return null;
    
        if (type == NotificationType.FOLLOW_REQUEST)
            return reject_follow_request ();
        
        var url = "%s/api/v1/notifications/dismiss?id=%lld".printf (accounts.formal.instance, id);
        var msg = new Soup.Message("POST", url);
        network.queue(msg);
        return msg;
    }
    
    public Soup.Message accept_follow_request () {
        var url = "%s/api/v1/follow_requests/%lld/authorize".printf (accounts.formal.instance, account.id);
        var msg = new Soup.Message("POST", url);
        network.queue(msg);
        return msg;
    }
    
    public Soup.Message reject_follow_request () {
        var url = "%s/api/v1/follow_requests/%lld/reject".printf (accounts.formal.instance, account.id);
        var msg = new Soup.Message("POST", url);
        network.queue(msg);
        return msg;
    }

}
