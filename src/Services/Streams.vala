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
		protected int timeout = 1;

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
				timeout = int.min (timeout*2, 6);
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

	static void decode (Bytes bytes, out Json.Node root, out Json.Object obj, out string event) throws Error {
		var msg = (string) bytes.get_data ();
		var parser = new Json.Parser ();
		parser.load_from_data (msg, -1);
		root = parser.steal_root ();
		obj = root.get_object ();
		event = obj.get_string_member ("event");
	}

	static Json.Node payload (Json.Object obj) {
		var payload = obj.get_string_member ("payload");
		var data = Soup.URI.decode (payload);
		var parser = new Json.Parser ();
		parser.load_from_data (data, -1);
		return parser.steal_root ();
	}

	static void emit (Bytes bytes, Connection c) throws Error {
		if (!settings.live_updates)
			return;

		Json.Node root;
		Json.Object root_obj;
		string ev;
		decode (bytes, out root, out root_obj, out ev);

		// c.subscribers.@foreach (s => {
		// 	warning ("%s: %s for %s", c.name, e, get_subscriber_name (s));
		// 	return false;
		// });

		switch (ev) {
			case "update":
				var node = payload (root_obj);
				var status = Entity.from_json (typeof (API.Status), node) as API.Status;
				c.subscribers.@foreach (s => {
					s.on_status_added (status);
					return true;
				});
				break;
			case "delete":
				var id = root_obj.get_string_member ("payload");
				c.subscribers.@foreach (s => {
					s.on_status_removed (id);
					return true;
				});
				break;
			case "notification":
				var node = payload (root_obj);
				var notif = Entity.from_json (typeof (API.Notification), node) as API.Notification;
				c.subscribers.@foreach (s => {
					s.on_notification (notif);
					return true;
				});
				break;
			default:
				warning (@"Unknown websocket event: \"$ev\". Ignoring.");
				break;
		}
	}

	public void force_delete (string id) {
		connections.get_values ().@foreach (c => {
			c.subscribers.@foreach (s => {
				s.on_status_removed (id);
				return false;
			});
		});
	}

}
