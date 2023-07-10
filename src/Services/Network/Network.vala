using Soup;
using GLib;
using Gdk;
using Json;

public class Tuba.Network : GLib.Object {

	public signal void started ();
	public signal void finished ();

	public delegate void ErrorCallback (int32 code, string reason);
	public delegate void SuccessCallback (Session session, Message msg, InputStream in_stream) throws Error;
	public delegate void NodeCallback (Json.Node node, Message msg) throws Error;
	public delegate void ObjectCallback (Json.Object node) throws Error;

	public Soup.Session session { get; set; }
	int requests_processing = 0;

	construct {
		session = new Soup.Session () {
			user_agent = @"$(Build.NAME)/$(Build.VERSION) libsoup/$(Soup.get_major_version()).$(Soup.get_minor_version()).$(Soup.get_micro_version()) ($(Soup.MAJOR_VERSION).$(Soup.MINOR_VERSION).$(Soup.MICRO_VERSION))" // vala-lint=line-length
		};
		session.request_unqueued.connect (msg => {
			requests_processing--;
			if (requests_processing <= 0)
				finished ();
		});
	}

	public void queue (
		owned Soup.Message msg,
		GLib.Cancellable? cancellable,
		owned SuccessCallback cb,
		owned ErrorCallback? ecb
	) {
		requests_processing++;
		started ();

		message (@"$(msg.method): $(msg.uri.to_string ())");

		session.send_async.begin (msg, 0, cancellable, (obj, res) => {
			try {
				var in_stream = session.send_async.end (res);

				var status = msg.status_code;
				if (status == Soup.Status.OK) {
					try {
						if (cb != null)
							cb (session, msg, in_stream);
					} catch (Error e) {
						warning (@"Error in session: $(e.message)");
					}
				} else if (status == GLib.IOError.CANCELLED) {
					debug ("Message is cancelled. Ignoring callback invocation.");
				} else {
					if (ecb == null) {
						critical (@"Request \"$(msg.uri.to_string ())\" failed: $status $(msg.reason_phrase)");
					} else {
						var parser = Network.get_parser_from_inputstream (in_stream);
						var root = network.parse (parser);
						var error_msg = root.get_string_member_with_default ("error", msg.reason_phrase);

						ecb ((int32) status, error_msg);
					}
				}
			} catch (GLib.Error e) {
				warning (e.message);
				if (ecb != null) {
					ecb ((int32) e.code, e.message);
				}
			}
		});
	}

	public void on_error (int32 code, string message) {
		warning (message);
		app.toast (message);
	}

	public Json.Node parse_node (Json.Parser parser) {
		return parser.get_root ();
	}

	public Json.Object parse (Json.Parser parser) {
		return parse_node (parser).get_object ();
	}

	public static Json.Parser get_parser_from_inputstream (InputStream in_stream) throws Error {
		var parser = new Json.Parser ();
		parser.load_from_stream (in_stream);
		return parser;
	}

	public static Json.Array? get_array_mstd (Json.Parser parser) {
		return parser.get_root ().get_array ();
	}

	public static uint get_array_size (Json.Parser parser) {
		return get_array_mstd (parser).get_length ();
	}

	public static void parse_array (Soup.Message msg, Json.Parser parser, owned NodeCallback cb) throws Error {
		get_array_mstd (parser).foreach_element ((array, i, node) => {
			try {
				cb (node, msg);
			} catch (Error e) {
				warning (@"Error parsing array: $(e.message)");
			}
		});
	}

}
