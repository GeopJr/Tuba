using GLib;
using Soup;

public class Tootle.Notificator : GLib.Object {
    
    weak Account account;
    WebsocketConnection? connection;
    
    public Notificator (Account acc){
        Object ();
        account = acc;
    }
    
    public async void start () {
        var msg = account.get_stream ();
        connection = yield Tootle.network.stream (msg);
        connection.error.connect (on_error);
        connection.message.connect (on_message);
        debug ("Receiving notifications for %lld", account.id);
    }
    
    public void close () {
        debug ("Closing notifications for %lld", account.id);
        connection.close (0, null);
    }
    
    private void on_error (Error e) {
        error (e.message);
    }
    
    private void on_message (int i, Bytes bytes) {
        var network = Tootle.network;
        var msg = (string) bytes.get_data ();
        
        var parser = new Json.Parser ();
        parser.load_from_data (msg, -1);
        var root = parser.get_root ().get_object ();
        
        var type = root.get_string_member ("event");
        switch (type) {
            case "update":
                var status = Status.parse (sanitize (root));
                network.status_added (status);
                break;
            case "delete":
                var id = int64.parse (root.get_string_member("payload"));
                network.status_removed (id);
                break;
            case "notification":
                var notif = Notification.parse (sanitize (root));
                toast (notif);
                network.notification (notif);
                break;
            default:
                warning ("Unknown push event: %s", type);
                break;
        }
        
    }
    
    private Json.Object sanitize (Json.Object root) {
        var payload = root.get_string_member ("payload");
        var sanitized = Soup.URI.decode (payload);
        var parser = new Json.Parser ();
        parser.load_from_data (sanitized, -1);
        return parser.get_root ().get_object ();
    }
    
    private void toast (Notification obj) {
        var tags = new Regex("<(.|\n)*?>", RegexCompileFlags.CASELESS);
        var title = tags.replace(obj.type.get_desc (obj.account), -1, 0, "");
        var notification = new GLib.Notification (title);
        if (obj.status != null)
            notification.set_body (tags.replace(obj.status.content, -1, 0, ""));
        Tootle.app.send_notification (Tootle.app.application_id + ":" + obj.id.to_string (), notification);
    }
    
}
