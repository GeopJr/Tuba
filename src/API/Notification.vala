public class Tootle.Notification{

    public int64 id;
    public NotificationType type;
    public string created_at;
    
    public Status? status;
    public Account? account;

    public Notification(int64 id) {
        this.id = id;
    }

    public static Notification parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var notification = new Notification (id);
        
        notification.type = NotificationType.from_string (obj.get_string_member ("type"));
        notification.created_at = obj.get_string_member ("created_at");
        
        if (obj.has_member ("status"))
            notification.status = Status.parse(obj.get_object_member ("status"));
        if (obj.has_member ("account"))
            notification.account = Account.parse(obj.get_object_member ("account"));
        
        return notification;
    }

}
