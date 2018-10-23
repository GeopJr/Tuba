using Soup;
using GLib;
using Gdk;
using Json;

public class Tootle.Network : GLib.Object {

    public signal void started ();
    public signal void finished ();
    
    public signal void notification (Notification notification);
    public signal void status_removed (int64 id);
    
    private int requests_processing = 0;
    private Soup.Session session;

    construct {
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

    public Network () {}
    
    public async WebsocketConnection stream (Soup.Message msg) throws GLib.Error {
        return yield session.websocket_connect_async (msg, null, null, null);
    }
    
    public Soup.Message queue (Soup.Message msg, owned Soup.SessionCallback? cb = null) {
        requests_processing++;
        started ();
        
        var formal = accounts.formal;
        if(formal != null)
            msg.request_headers.append ("Authorization", "Bearer " + formal.token);
        
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
                    app.error (_("TLS Error"), _("Can't ensure secure connection: ")+err);
                    return;
                default:
                    break;
            }
            
            if (mess.status_code != Soup.Status.OK) {
                var phrase = Soup.Status.get_phrase (mess.status_code);
                app.toast (_("Error: %s").printf(phrase));
                return;
            }
            
            if (cb != null)
                cb (sess, mess);
                
            msg.request_body.free ();
            msg.response_body.free ();
            msg.request_headers.free ();
            msg.response_headers.free ();
        });
        return msg;
    }
    
    public void queue_custom (Soup.Message msg, owned Soup.SessionCallback? cb = null) {
        requests_processing++;
        started ();
        
        msg.finished.connect_after (() => {
            msg.request_body.free ();
            msg.response_body.free ();
            msg.request_headers.free ();
            msg.response_headers.free ();
        });
        session.queue_message (msg, cb);
    }
    
    public Json.Object parse (Soup.Message msg) throws GLib.Error {
        // debug ("Status Code: %u", msg.status_code);
        // debug ("Message length: %lld", msg.response_body.length);
        // debug ("Object: %s", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_object ();
    }
    
    public Json.Array parse_array (Soup.Message msg) throws GLib.Error {
        // debug ("Status Code: %u", msg.status_code);
        // debug ("Message length: %lld", msg.response_body.length);
        // debug ("Array: %s", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_array ();
    }
    
    public void load_avatar (string url, Granite.Widgets.Avatar avatar, int size){
        if (settings.cache) {
            image_cache.load_avatar (url, avatar, size);
            return;
        }
        
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
            if (msg.status_code != Soup.Status.OK) {
                avatar.show_default (size);
                return;
            }
            
            var data = msg.response_body.data;
            var stream = new MemoryInputStream.from_data (data);
            var pixbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, size, size, true);
            avatar.pixbuf = pixbuf.scale_simple (size, size, Gdk.InterpType.BILINEAR);
        });
        network.queue_custom (msg);
    }
    
    public void load_image (string url, Gtk.Image image) {
        if (settings.cache) {
            image_cache.load_image (url, image);
            return;
        }
        
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
            if (msg.status_code != Soup.Status.OK) {
                image.set_from_icon_name ("image-missing", Gtk.IconSize.LARGE_TOOLBAR);
                return;
            }
            
            var data = msg.response_body.data;
            var stream = new MemoryInputStream.from_data (data);
            var pixbuf = new Gdk.Pixbuf.from_stream (stream);
            image.set_from_pixbuf (pixbuf);
        });
        network.queue_custom (msg);
    }
    
    public void load_scaled_image (string url, Gtk.Image image, int size) {
        if (settings.cache) {
            image_cache.load_scaled_image (url, image, size);
            return;
        }
        
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
            if (msg.status_code != Soup.Status.OK) {
                image.set_from_icon_name ("image-missing", Gtk.IconSize.LARGE_TOOLBAR);
                return;
            }

            var data = msg.response_body.data;
            var stream = new MemoryInputStream.from_data (data);
            var pixbuf = new Gdk.Pixbuf.from_stream_at_scale (stream, size, size, true);
            image.set_from_pixbuf (pixbuf);
        });
        network.queue_custom (msg);
    }
    
}
