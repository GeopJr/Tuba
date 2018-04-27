using Soup;
using GLib;
using Json;

public class Tootle.NetManager : GLib.Object{

    public abstract signal void started();
    public abstract signal void finished();
    
    private int requests_processing = 0;
    private Soup.Session session;

    construct{
        session = new Soup.Session ();
        session.request_unqueued.connect (() => {
            requests_processing--;
            if(requests_processing <= 0)
                finished ();
        });
    }

    public NetManager(){
        GLib.Object();
    }
    
    public Soup.Message queue(Soup.Message msg, Soup.SessionCallback cb){
        requests_processing++;
        started ();
        
        var token = Tootle.settings.access_token;
        if(token != "null")
            msg.request_headers.append ("Authorization", "Bearer " + token);
        
        session.queue_message (msg, cb);
        return msg;
    }
    
    public Json.Object parse(Soup.Message msg) throws GLib.Error{
        // stdout.printf ("Status Code: %u\n", msg.status_code);
        // stdout.printf ("Message length: %lld\n", msg.response_body.length);
        // stdout.printf ("Object: \n%s\n", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_object ();
    }
    
    public Json.Array parse_array(Soup.Message msg) throws GLib.Error{
        // stdout.printf ("Status Code: %u\n", msg.status_code);
        // stdout.printf ("Message length: %lld\n", msg.response_body.length);
        // stdout.printf ("Array: \n%s\n", (string) msg.response_body.data);
    
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ().get_array ();
    }

}
