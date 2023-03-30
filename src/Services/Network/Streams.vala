using Soup;
using Gee;

public class Tuba.Streams : Object {

	protected HashTable<string, Connection> connections {
		get;
		set;
		default = new HashTable<string, Connection> (GLib.str_hash, GLib.str_equal);
	}

	public void subscribe (string? url, Streamable s) {
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
	}

	public void unsubscribe (string? url, Streamable s) {
		if (url == null)
			return;

		if (connections.contains (url)) {
			var unused = connections.@get (url).remove (s);
			if (unused)
				connections.remove (url);
		}
	}

	// public void force_delete (string id) {
	// 	connections.get_values ().@foreach (c => {
	// 		c.subscribers.@foreach (s => {
	// 			s.on_status_removed (id);
	// 			return true;
	// 		});
	// 	});
	// }

	protected class Connection : Object {
		public ArrayList<Streamable> subscribers;
		protected WebsocketConnection socket;
		protected Message msg;

		protected bool closing = false;
		protected int timeout = 1;

		public string name {
			owned get {
				var url = msg.get_uri ().to_string ();
				return url.slice (0, url.last_index_of ("&access_token"));
			}
		}

		public Connection (string url) {
			this.subscribers = new ArrayList<Streamable> ();
			this.msg = new Message ("GET", url);
		}

		public bool start () {
			message (@"Opening stream: $name");
			network.session.websocket_connect_async.begin (msg, null, null, 0, null, (obj, res) => {
				try {
					socket = network.session.websocket_connect_async.end (res);
					socket.error.connect (on_error);
					socket.closed.connect (on_closed);
					socket.message.connect (on_message);
				} catch (Error e) {
					warning (@"Error opening stream: $(e.message)");
				}
			});
			return false;
		}

		public void add (Streamable s) {
			info ("%s > %s", s.get_subscriber_name (), name);
			subscribers.add (s);
		}

		public bool remove (Streamable s) {
			if (subscribers.contains (s)) {
				info ("%s X %s", s.get_subscriber_name (), name);
				subscribers.remove (s);
			}

			if (subscribers.size <= 0) {
				message (@"Closing: $name");
				closing = true;
				if (socket != null)
					socket.close (0, null);
				return true;
			}
			return false;
		}

		void on_error (Error e) {
			if (closing)
				return;

			warning (@"Error in $name: $(e.message)");
		}

		void on_closed () {
			if (!closing) {
				warning (@"DISCONNECTED: $name. Reconnecting in $timeout seconds.");
				GLib.Timeout.add_seconds (timeout, start);
				timeout = int.min (timeout*2, 6);
			}
			message (@"Closing stream: $name");
		}

		protected virtual void on_message (int i, Bytes bytes) {
			try {
				Streamable.Event ev;
				decode (bytes, out ev);

				subscribers.@foreach (s => {
					message (@"$(name): $(ev.type) for $(s.get_subscriber_name ())");
					s.stream_event[ev.type] (ev);
					return true;
				});
			}
			catch (Error e) {
				warning (@"Failed to handle websocket message. Reason: $(e.message)");
			}
		}

		void decode (Bytes bytes, out Streamable.Event event) throws Error{
			var msg = (string) bytes.get_data ();
			var parser = new Json.Parser ();
			parser.load_from_data (msg, -1);
			var obj = parser.steal_root ().get_object ();
			if (obj == null)
				throw new Oopsie.INSTANCE ("Failed to decode message as an Object");

			if (!obj.has_member ("event"))
				throw new Oopsie.INSTANCE ("No event specified");
			event = Streamable.Event ();
			event.type = obj.get_string_member ("event");
			event.payload = obj.get_member ("payload");
		}

	}

}
