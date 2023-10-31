public class Tuba.Streams : Object {

	protected HashTable<string, Connection> connections {
		get;
		set;
		default = new HashTable<string, Connection> (GLib.str_hash, GLib.str_equal);
	}

	public void subscribe (string? url, Streamable s) {
		#if DEV_MODE
			return;
		#endif

		if (url == null)
			return;

		if (connections.contains (url)) {
			connections[url].add (s);
		} else {
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
		public Gee.ArrayList<Streamable> subscribers;
		protected Soup.WebsocketConnection socket;

		protected bool closing = false;
		protected int timeout = 1;

		public string url { get; private set; }

		public string name {
			owned get {
				return url.slice (0, url.last_index_of ("&access_token"));
			}
		}

		public Connection (string url) {
			this.subscribers = new Gee.ArrayList<Streamable> ();
			this.url = url;
		}

		public bool start () {
			debug (@"Opening stream: $name");
			network.session.websocket_connect_async.begin (new Soup.Message ("GET", url), null, null, 0, null, (obj, res) => {
				try {
					socket = network.session.websocket_connect_async.end (res);
					socket.keepalive_interval = 30;

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
				debug (@"Closing: $name");
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
			socket = null;
			if (!closing) {
				warning (@"DISCONNECTED: $name. Reconnecting in $timeout seconds.");
				GLib.Timeout.add_seconds (timeout, start);
				timeout = int.min (timeout * 2, 6);
			}
			debug (@"Closing stream: $name");
		}

		protected virtual void on_message (int i, Bytes bytes) {
			try {
				Streamable.Event ev;
				decode (bytes, out ev);

				warning ("GOT MSG");
				subscribers.@foreach (s => {
					warning (@"$(name): $(ev.type) for $(s.get_subscriber_name ())");
					s.stream_event[ev.type] (ev);
					return true;
				});
			}
			catch (Error e) {
				warning (@"Failed to handle websocket message. Reason: $(e.message)");
			}
		}

		void decode (Bytes bytes, out Streamable.Event event) throws Error {
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
