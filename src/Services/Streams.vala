using Soup;
using Gee;

public class Tootle.Streams : Object {

	protected HashTable<string, Connection> connections {
		get;
		set;
		default = new HashTable<string, Connection> (GLib.str_hash, GLib.str_equal);
	}

	protected class Connection : Object {
		public ArrayList<IStreamListener> subscribers;
		protected WebsocketConnection socket;
		protected Message msg;

		protected bool closing = false;
		protected int timeout = 2;

		public string name {
			owned get {
				var url = msg.get_uri ().to_string (false);
				return url.slice (0, url.last_index_of ("&access_token"));
			}
		}

		public Connection (string url) {
			this.subscribers = new ArrayList<IStreamListener> ();
			this.msg = new Message ("GET", url);
		}

		public bool start () {
			info (@"Opening stream: $name");
			network.session.websocket_connect_async.begin (msg, null, null, null, (obj, res) => {
				socket = network.session.websocket_connect_async.end (res);
				socket.error.connect (on_error);
				socket.closed.connect (on_closed);
				socket.message.connect (on_message);
			});
			return false;
		}

		public void add (IStreamListener s) {
			info ("%s > %s", get_subscriber_name (s), name);
			subscribers.add (s);
		}

		public void remove (IStreamListener s) {
			if (subscribers.contains (s)) {
				info ("%s X %s", get_subscriber_name (s), name);
				subscribers.remove (s);
			}

			if (subscribers.size <= 0) {
				info (@"Closing: $name");
				closing = true;
				socket.close (0, null);
			}
		}

		void on_error (Error e) {
			if (!closing)
				warning (@"Error in $name: $(e.message)");
		}

		void on_closed () {
			if (!closing) {
				warning (@"DISCONNECTED: $name. Reconnecting in $timeout seconds.");
				GLib.Timeout.add_seconds (timeout, start);
				timeout = int.min (timeout*2, 30);
			}
			warning (@"Closing stream: $name");
		}

		void on_message (int i, Bytes bytes) {
			try {
				emit (bytes, this);
			}
			catch (Error e) {
				warning (@"Couldn't handle websocket event. Reason: $(e.message)");
			}
		}
	}

	public void subscribe (string? url, IStreamListener s, out string cookie) {
		if (url == null)
			return;

		if (connections.contains (url)) {
			connections[url].add (s);
		}
		else {
			var con = new Connection (url);
			connections[url] = con;
			con.add (s);
			con.start ();
		}
		cookie = url;
	}

	public void unsubscribe (string? cookie, IStreamListener s) {
		var url = cookie;
		if (url == null)
			return;

		if (connections.contains (url))
			connections.@get (url).remove (s);
	}

	static string get_subscriber_name (Object s) {
		return s.get_type ().name ();
	}

	static void decode (Bytes bytes, out string event, out Json.Object root) throws Error {
		var msg = (string) bytes.get_data ();
		var parser = new Json.Parser ();
		parser.load_from_data (msg, -1);
		root = parser.get_root ().get_object ();
		event = root.get_string_member ("event");
	}

	static Json.Object sanitize (Json.Object root) {
		var payload = root.get_string_member ("payload");
		var sanitized = Soup.URI.decode (payload);
		var parser = new Json.Parser ();
		parser.load_from_data (sanitized, -1);
		return parser.get_root ().get_object ();
	}

	static void emit (Bytes bytes, Connection c) throws Error {
		if (!settings.live_updates)
			return;

		string e;
		Json.Object root;
		decode (bytes, out e, out root);

		// c.subscribers.@foreach (s => {
		// 	warning ("%s: %s for %s", c.name, e, get_subscriber_name (s));
		// 	return false;
		// });

		switch (e) {
			case "update":
				var obj = new API.Status (sanitize (root));
				c.subscribers.@foreach (s => {
					s.on_status_added (obj);
					return true;
				});
				break;
			case "delete":
				var id = int64.parse (root.get_string_member ("payload"));
				c.subscribers.@foreach (s => {
					s.on_status_removed (id);
					return true;
				});
				break;
			case "notification":
				var obj = new API.Notification (sanitize (root));
				c.subscribers.@foreach (s => {
					s.on_notification (obj);
					return true;
				});
				break;
			default:
				warning (@"Unknown websocket event: \"$e\". Ignoring.");
				break;
		}
	}

	public void force_delete (int64 id) {
		warning (@"Force removing status id $id");
		connections.get_values ().@foreach (c => {
			c.subscribers.@foreach (s => {
				s.on_status_removed (id);
				return false;
			});
		});
	}

}
