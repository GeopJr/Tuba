using Soup;
using GLib;
using Gdk;
using Json;

public class Tooth.Network : GLib.Object {

	public signal void started ();
	public signal void finished ();

	public delegate void ErrorCallback (int32 code, string reason);
	public delegate void SuccessCallback (Session session, Message msg) throws Error;
	public delegate void NodeCallback (Json.Node node, Message msg) throws Error;
	public delegate void ObjectCallback (Json.Object node) throws Error;

	public Soup.Session session { get; set; }
	int requests_processing = 0;

	construct {
		session = new Soup.Session () {
			ssl_strict = true,
			ssl_use_system_ca_file = true
		};
		session.request_unqueued.connect (msg => {
			requests_processing--;
			if (requests_processing <= 0)
				finished ();
		});
	}

	public void cancel (Soup.Message? msg) {
		if (msg == null)
			return;

		switch (msg.status_code) {
			case Soup.Status.CANCELLED:
			case Soup.Status.OK:
				return;
		}

		debug ("Cancelling message");
		session.cancel_message (msg, Soup.Status.CANCELLED);
	}

	public void queue (owned Soup.Message mess, owned SuccessCallback cb, owned ErrorCallback ecb) {
		requests_processing++;
		started ();

		message (@"$(mess.method): $(mess.uri.to_string (false))");

		try {
			session.queue_message (mess, (sess, msg) => {
				var status = msg.status_code;
				if (status == Soup.Status.OK)
					cb (session, msg);
				else if (status == Soup.Status.CANCELLED)
					debug ("Message is cancelled. Ignoring callback invocation.");
				else
					critical (@"Should be ecb: $status $(msg.reason_phrase)");
					//  ecb ((int32) status, msg.reason_phrase);
			});
		}
		catch (Error e) {
			warning (@"Exception in network queue: $(e.message)");
			ecb (0, e.message);
		}
	}

	public void on_error (int32 code, string message) {
		warning (message);
		app.toast (message);
	}

	public Json.Node parse_node (Soup.Message msg) throws Error {
		var parser = new Json.Parser ();
		parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
		return parser.get_root ();
	}

	public Json.Object parse (Soup.Message msg) throws Error {
		return parse_node (msg).get_object ();
	}

	public static Json.Array? get_array_mstd (Soup.Message msg) throws Error {
		var parser = new Json.Parser ();
		parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
		return parser.get_root ().get_array ();
	}

	public static uint get_array_size (Soup.Message msg) throws Error {
		var parser = new Json.Parser ();
		parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
		return parser.get_root ().get_array ().get_length();
	}

	public static void parse_array (Soup.Message msg, owned NodeCallback cb) throws Error {
		var parser = new Json.Parser ();
		parser.load_from_data ((string) msg.response_body.flatten ().data, -1);
		parser.get_root ().get_array ().foreach_element ((array, i, node) => {
			cb (node, msg);
		});
	}

}
