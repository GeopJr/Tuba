public interface Tuba.Streamable : Object {

	public struct Event {
		public string type;
		Json.Node? payload;

		public string get_string () throws Error {
			return payload.get_string ();
		}

		public Json.Node get_node () throws Error {
			var parser = new Json.Parser ();
			parser.load_from_data (get_string (), -1);
			return parser.steal_root ();
		}

		public Json.Object get_object () throws Error {
			return get_node ().get_object ();
		}
	}

	public abstract string? t_connection_url { get; set; }
	public abstract bool subscribed { get; set; default = false; }

	public abstract string? get_stream_url ();

	[Signal (detailed = true)]
	public signal void stream_event (Event ev);

	void subscribe () {
		streams.unsubscribe (t_connection_url, this);
		streams.subscribe (get_stream_url (), this);
		t_connection_url = get_stream_url ();
	}

	void unsubscribe () {
		streams.unsubscribe (t_connection_url, this);
		t_connection_url = null;
	}

	protected void forward (string url, Streamable.Event ev) {
		if (!subscribed) return;
		streams.forward (url, ev);
	}

	public string get_subscriber_name () {
		return this.get_type ().name ();
	}

	protected void construct_streamable () {
		settings.notify["live-updates"].connect (on_streaming_policy_changed);
		settings.notify["public-live-updates"].connect (on_streaming_policy_changed);
		on_streaming_policy_changed ();

		notify["subscribed"].connect (update_stream);
		notify["stream_url"].connect (update_stream);
		app.notify["is-online"].connect (on_network_change);
		update_stream ();
	}

	protected void destruct_streamable () {
		unsubscribe ();
	}

	protected void on_network_change () {
		if (app.is_online) {
			update_stream ();
		} else {
			unsubscribe ();
		}
	}

	protected void update_stream () {
		// debug (get_subscriber_name ()+": UPDATED to "+subscribed.to_string ());

		unsubscribe ();
		if (subscribed)
			subscribe ();
	}

	protected virtual void on_streaming_policy_changed () {}

}
