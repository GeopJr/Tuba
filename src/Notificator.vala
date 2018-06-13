using GLib;
using Soup;

public class Tootle.Notificator : GLib.Object {
    
    private WebsocketConnection? connection;
    private Soup.Message msg;
    private bool closing = false;
    private int timeout = 2;
    
    public abstract signal void notification (ref Notification notification);
    public abstract signal void status_added (ref Status status);
    public abstract signal void status_removed (int64 id);
    
    public Notificator (Soup.Message msg){
        Object ();
        this.msg = msg;
        this.msg.priority = Soup.MessagePriority.VERY_HIGH;
    }
    
    public async void start () {
        try {
            debug ("Starting notificator");
            connection = yield Tootle.network.stream (msg);
            connection.error.connect (on_error);
            connection.message.connect (on_message);
            connection.closed.connect (on_closed);
            timeout = 2;
        }
        catch (GLib.Error e) {
            warning (e.message);
            on_closed ();
        }
    }
    
    public void close () {
        debug ("Stopping notificator");
        closing = true;
        connection.close (0, null);
    }
    
    private bool reconnect () {
        start ();
        return false;
    }
    
    private void on_closed () {
        if (closing)
            return;
        
        debug ("Notificator aborted. Reconnecting in %i seconds.", timeout);
        GLib.Timeout.add_seconds (timeout, reconnect);
        timeout = int.min (timeout*2, 60);
    }
    
    private void on_error (Error e) {
        error (e.message);
    }
    
    private void on_message (int i, Bytes bytes) {
        var msg = (string) bytes.get_data ();
        
        var parser = new Json.Parser ();
        parser.load_from_data (msg, -1);
        var root = parser.get_root ().get_object ();
        
        var type = root.get_string_member ("event");
        switch (type) {
            case "update":
                if (!settings.live_updates)
                    return;
                
                var status = Status.parse (sanitize (root));
                status_added (ref status);
                break;
            case "delete":
                if (!settings.live_updates)
                    return;
                
                var id = int64.parse (root.get_string_member("payload"));
                status_removed (id);
                break;
            case "notification":
                var notif = Notification.parse (sanitize (root));
                notification (ref notif);
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
    
}
