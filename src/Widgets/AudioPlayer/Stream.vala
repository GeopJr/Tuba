// Smoothing function adapted from https://gitlab.gnome.org/GNOME/gnome-control-center/-/blob/ea8bafc5d1ebb945a0806b03dea0c3abf29c58d9/panels/sound/cc-level-bar.c

public class Tuba.Widgets.Audio.Stream : GLib.Object {
	const double SMOOTHING = 0.3;
	Gst.Bin pipeline;
	Gst.Bus bus;
	Gst.Element uridecodebin;

	public signal void ended ();
	public double level { get; private set; default=0.0; }
	public double volume { get; set; default=1.0; }
	public bool muted { get; set; default=false; }

	public double progress {
		set {
			pipeline.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH | Gst.SeekFlags.KEY_UNIT, (int64) (value / 10 * duration));
			update_metadata ();
		}
	}

	public int64 duration { get; private set; default=0; }
	public int64 current { get; private set; default=0; }

	private string _url = "";
	public string url {
		get {
			return _url;
		}
		set {
			_url = value;
			uridecodebin.set_property ("uri", value);
		}
	}

	private Gst.State _state = Gst.State.NULL;
	public Gst.State state {
		get { return _state; }
		set {
			pipeline.set_state (value);
		}
	}

	private bool update_metadata () {
		if (bus == null) return false;
		if (this.state < Gst.State.PAUSED) return true;
		update_current ();

		return true;
	}

	private bool bus_callback (Gst.Bus bus, Gst.Message message) {
		switch (message.type) {
		case Gst.MessageType.ERROR:
			GLib.Error err;
			string debug_log;
			message.parse_error (out err, out debug_log);
			critical (@"Gst Error: $(err.message)");
			debug (@"Gst Error Debug: $debug_log");
			break;
		case Gst.MessageType.EOS:
			pipeline.seek_simple (Gst.Format.TIME, Gst.SeekFlags.FLUSH, 0);
			ended ();
			break;
		case Gst.MessageType.STATE_CHANGED:
			message.parse_state_changed (null, out _state, null);
			break;
		case Gst.MessageType.ELEMENT:
			unowned Gst.Structure s = message.get_structure ();

			if (s != null && s.get_name () == "level") {
				unowned GLib.Value peaks = s.get_value ("peak");
				unowned GLib.ValueArray value_array = (GLib.ValueArray) peaks.get_boxed ();

				double level_sum = 0;
				foreach (var val in value_array) {
				  level_sum += val.get_double ();
				}

				var levels = Math.pow (10, (level_sum / value_array.n_values) / 20);
				level = (levels * SMOOTHING) + (level * (1.0 - SMOOTHING));
			}
			break;
		case Gst.MessageType.ASYNC_DONE:
			if (this.duration == 0) {
				update_duration ();
			}
			break;
		case Gst.MessageType.DURATION_CHANGED:
			update_duration ();
			break;
		default:
			break;
		}

		return true;
	}

	private void update_duration () {
		int64 t_duration = 0;
		if (!pipeline.query_duration (Gst.Format.TIME, out t_duration)) {
			debug (@"Couldn't get duration of $url");
			return;
		}
		if (t_duration != this.duration) this.duration = t_duration;
	}

	private void update_current () {
		int64 t_current = 0;
		if (!pipeline.query_position (Gst.Format.TIME, out t_current)) {
			debug (@"Couldn't get current position of $url");
			return;
		}
		if (t_current != this.current) this.current = t_current;
	}

	uint timeout_id = -1;
	construct {
		string pipestr = "uridecodebin name=uridecodebin ! audioconvert ! audio/x-raw,channels=2 ! volume name=volume ! level name=level interval=75000000 ! autoaudiosink name=sink";
		try {
			pipeline = (Gst.Bin) Gst.parse_launch (pipestr);
			uridecodebin = pipeline.get_by_name ("uridecodebin");

			var volume = pipeline.get_by_name ("volume");
			this.bind_property ("volume", volume, "volume", BindingFlags.SYNC_CREATE);
			//  this.bind_property ("muted", volume, "muted", BindingFlags.SYNC_CREATE);

			var level = pipeline.get_by_name ("level");
			level.set_property ("post-messages", true);

			var sink = pipeline.get_by_name ("sink");
			sink.set_property ("sync", true);

			bus = pipeline.get_bus ();
			bus.add_watch (0, bus_callback);

			timeout_id = GLib.Timeout.add_seconds (1, update_metadata);
		} catch (Error e) {
			critical (@"Error while constructing pipeline: $(e.message)");
		}
	}

	// Without disconnecting everything
	// it leaks.
	public void destroy () {
		if (timeout_id > 0) GLib.Source.remove (timeout_id);
		bus.remove_watch ();
		bus = null;
		this.state = Gst.State.NULL;
		pipeline = null;
	}

	~Stream () {
		debug ("Destroying AudioStream");
	}
}
