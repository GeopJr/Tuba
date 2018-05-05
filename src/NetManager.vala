using Soup;
using GLib;
using Json;

public class Tootle.NetManager : GLib.Object {

    public abstract signal void started();
    public abstract signal void finished();
    
    private int requests_processing = 0;
    private Soup.Session session;

    construct {
        session = new Soup.Session ();
        session.ssl_strict = true;
        session.ssl_use_system_ca_file = true;
        session.timeout = 20;
        session.max_conns = 15;
        session.request_unqueued.connect (() => {
            requests_processing--;
            if(requests_processing <= 0)
                finished ();
        });
        
        // Soup.Logger logger = new Soup.Logger (Soup.LoggerLogLevel.MINIMAL, -1);
        // session.add_feature (logger);
    }

    public NetManager() {
        GLib.Object();
    }
    
    public Soup.Message queue(Soup.Message msg, Soup.SessionCallback? cb = null) {
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
    
    public Json.Object parse(Soup.Message msg) throws GLib.Error {
        // stdout.printf ("Status Code: %u\n", msg.status_code);
        // stdout.printf ("Message length: %lld\n", msg.response_body.length);
        // stdout.printf ("Object: \n%s\n", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_object ();
    }
    
    public Json.Array parse_array(Soup.Message msg) throws GLib.Error {
        // stdout.printf ("Status Code: %u\n", msg.status_code);
        // stdout.printf ("Message length: %lld\n", msg.response_body.length);
        // stdout.printf ("Array: \n%s\n", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_array ();
    }
    
    public bool is_active_in_background () {
        return false;
    }

}
