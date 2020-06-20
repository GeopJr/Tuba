using Soup;
using GLib;
using Gdk;
using Json;

public class Tootle.Network : GLib.Object {

    public signal void started ();
    public signal void finished ();

	public delegate void ErrorCallback (int32 code, string reason);
	public delegate void SuccessCallback (Session session, Message msg) throws Error;
	public delegate void NodeCallback (Json.Node node, Message msg) throws Error;
	public delegate void ObjectCallback (Json.Object node) throws Error;

    private int requests_processing = 0;
    public Soup.Session session;

    construct {
        session = new Soup.Session ();
        session.ssl_strict = true;
        session.ssl_use_system_ca_file = true;
        session.timeout = 15;
        session.max_conns = 30;
        session.request_unqueued.connect (msg => {
            requests_processing--;
            if (requests_processing <= 0)
                finished ();
        });
    }

    // public void cancel_request (Soup.Message? msg) {
    //     if (msg == null)
    //         return;

    //     switch (msg.status_code) {
    //         case Soup.Status.CANCELLED:
    //         case Soup.Status.OK:
    //             return;
    //     }
    //     session.cancel_message (msg, Soup.Status.CANCELLED);
    // }

    public void queue (owned Soup.Message message, owned SuccessCallback? cb, owned ErrorCallback? errcb = null) {
        requests_processing++;
        started ();

        session.queue_message (message, (sess, msg) => {
        	var status = msg.status_code;
            if (status == Soup.Status.OK) {
            	try {
            		cb (session, msg);
            	}
            	catch (Error e) {
            		warning ("Exception on network request: %s", e.message);
                    if (errcb != null)
                    	errcb (Soup.Status.NONE, e.message);
            	}
            }
            else {
            	if (errcb != null)
            		errcb ((int32)status, describe_error ((int32)status));
            }
        });
    }

	public string describe_error (int32 code) {
	    var reason = Soup.Status.get_phrase (code);
		return @"$code: $reason";
	}

    public void on_error (int32 code, string message) {
        warning (message);
        app.toast (message);
    }

    public void on_show_error (int32 code, string message) {
    	warning (message);
    	app.error (_("Network Error"), message);
    }

    public Json.Node parse_node (Soup.Message msg) throws Error {
        var parser = new Json.Parser ();
        parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
        return parser.get_root ();
    }

    public Json.Object parse (Soup.Message msg) throws Error {
        return parse_node (msg).get_object ();
    }

}
