using Soup;
using GLib;
using Gdk;
using Json;

public class Tootle.NetManager : GLib.Object {

    public abstract signal void started ();
    public abstract signal void finished ();
    
    public abstract signal void notification (Notification notification);
    public abstract signal void status_added (Status status);
    public abstract signal void status_removed (int64 id);
    
    private int requests_processing = 0;
    private Soup.Session session;
    private Soup.Cache cache;
    public string cache_path;

    private Notificator notificator;

    construct {
        cache_path = "%s/%s".printf (GLib.Environment.get_user_cache_dir (), "tootle");
        cache = new Soup.Cache (cache_path, Soup.CacheType.SINGLE_USER);
        cache.set_max_size (1024 * 1024 * 16);
    
        session = new Soup.Session ();
        session.ssl_strict = true;
        session.ssl_use_system_ca_file = true;
        session.timeout = 20;
        session.max_conns = 15;
        session.request_unqueued.connect (msg => {
            requests_processing--;
            if(requests_processing <= 0)
                finished ();
        });
        
        // Soup.Logger logger = new Soup.Logger (Soup.LoggerLogLevel.BODY, -1);
        // session.add_feature (logger);
    }

    public NetManager() {
        GLib.Object();
        if (Tootle.settings.cache) {
            session.add_feature (cache);
            Tootle.app.shutdown.connect (() => cache.flush ());
        }
        
        Tootle.accounts.switched.connect (acc => {
            if (acc == null) {
                if (notificator != null)
                    notificator.close ();
                return;
            }
            notificator = new Notificator (acc);
            notificator.start ();
        });
    }
    
    public void abort (Soup.Message msg) {
        session.cancel_message (msg, 0);
    }
    
    public async WebsocketConnection stream (Soup.Message msg) {
        return yield session.websocket_connect_async (msg, null, null, null);
    }
    
    public Soup.Message queue (Soup.Message msg, Soup.SessionCallback? cb = null) {
        requests_processing++;
        started ();
        
        var token = Tootle.settings.access_token;
        if(token != "null")
            msg.request_headers.append ("Authorization", "Bearer " + token);
        
        session.queue_message (msg, (sess, mess) => {
            switch (mess.tls_errors){
                case GLib.TlsCertificateFlags.UNKNOWN_CA:
                case GLib.TlsCertificateFlags.BAD_IDENTITY:
                case GLib.TlsCertificateFlags.NOT_ACTIVATED:
                case GLib.TlsCertificateFlags.EXPIRED:
                case GLib.TlsCertificateFlags.REVOKED:
                case GLib.TlsCertificateFlags.INSECURE:
                case GLib.TlsCertificateFlags.GENERIC_ERROR:
                    var err = mess.tls_errors.to_string ();
                    warning ("TLS error: "+err);
                    Tootle.app.error (_("TLS Error"), _("Can't ensure secure connection: ")+err);
                    return;
                default:
                    break;
            }
            
            if (cb != null)
                cb (sess, mess);
        });
        return msg;
    }
    
    public Json.Object parse (Soup.Message msg) throws GLib.Error {
        // stdout.printf ("Status Code: %u\n", msg.status_code);
        // stdout.printf ("Message length: %lld\n", msg.response_body.length);
        // stdout.printf ("Object: \n%s\n", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_object ();
    }
    
    public Json.Array parse_array (Soup.Message msg) throws GLib.Error {
        // stdout.printf ("Status Code: %u\n", msg.status_code);
        // stdout.printf ("Message length: %lld\n", msg.response_body.length);
        // stdout.printf ("Array: \n%s\n", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_array ();
    }
    
    public void load_avatar (string url, Granite.Widgets.Avatar avatar, int size){
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
                var loader = new PixbufLoader ();
                loader.set_size (size, size);
                loader.write (msg.response_body.data);
                loader.close ();
                avatar.pixbuf = loader.get_pixbuf ();
        });
        Tootle.network.queue (msg);
    }
    
    public void load_image (string url, Gtk.Image image) {
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
                var loader = new PixbufLoader ();
                loader.write (msg.response_body.data);
                loader.close ();
                image.set_from_pixbuf (loader.get_pixbuf ());
        });
        Tootle.network.queue (msg);
    }
    
    public void load_scaled_image (string url, Gtk.Image image, int size = 64) {
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
                var stream = new MemoryInputStream.from_data(msg.response_body.data, GLib.g_free);
                var pixbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, size, size, true);
                image.set_from_pixbuf (pixbuf);
        });
        Tootle.network.queue (msg);
    }
    
    

}
