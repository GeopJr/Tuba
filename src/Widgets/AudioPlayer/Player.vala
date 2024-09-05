public class Tuba.Widgets.Audio.Player : Adw.Bin {
	Audio.Stream player;
	Gtk.Overlay overlay;
	Audio.Visualizer visualizer;
	Gtk.Revealer controls_revealer;

	public string url {
		get { return player.url; }
		set { player.url = value; }
	}

	private bool _playing = false;
	public bool playing {
		get { return _playing; }
		set {
			_playing = value;
			player.state = value ? Gst.State.PLAYING : Gst.State.PAUSED;
		}
	}

	public double volume { get; set; default=1.0; }
	public double progress { get; set; default=0.0; }
	public bool ready { get; set; default=false; }

	public bool muted {
		get { return volume == 0.0; }
	}

	construct {
		overlay = new Gtk.Overlay () {
			vexpand = true,
			hexpand = true
		};

		player = new Audio.Stream ();
		this.bind_property ("volume", player, "volume", BindingFlags.SYNC_CREATE);
		this.bind_property ("progress", player, "progress", BindingFlags.SYNC_CREATE);

		var controls = new Widgets.Audio.Controls () {
			hexpand = true,
			valign = Gtk.Align.END
		};
		controls.bind_property ("volume", this, "volume", BindingFlags.SYNC_CREATE);
		controls.bind_property ("progress", this, "progress", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		controls.bind_property ("playing", this, "playing", BindingFlags.BIDIRECTIONAL);
		controls.bind_property ("ready", this, "ready", BindingFlags.SYNC_CREATE);

		controls_revealer = new Gtk.Revealer () {
			child = controls,
			transition_type = Gtk.RevealerTransitionType.NONE,
			valign = Gtk.Align.END
		};
		overlay.add_overlay (controls_revealer);

		player.bind_property ("current", controls, "current", BindingFlags.SYNC_CREATE);
		player.bind_property ("duration", controls, "duration", BindingFlags.SYNC_CREATE);
		player.bind_property ("ready", this, "ready", BindingFlags.SYNC_CREATE);
		player.ended.connect (on_ended);

		this.child = overlay;
	}

	private void on_ended () {
		this.playing = false;
	}

	bool should_hide_controls = true;
	protected void on_leave () {
		should_hide_controls = false;
	}

	double on_motion_last_x = 0.0;
	double on_motion_last_y = 0.0;
	protected void on_motion (double x, double y) {
		if (on_motion_last_x == x && on_motion_last_y == y) return;
		should_hide_controls = true;

		on_motion_last_x = x;
		on_motion_last_y = y;

		on_reveal_media_buttons ();
	}

	uint revealer_timeout = 0;
	private void on_reveal_media_buttons () {
		controls_revealer.set_reveal_child (true);
		if (revealer_timeout > 0) GLib.Source.remove (revealer_timeout);
		revealer_timeout = Timeout.add (5 * 1000, on_hide_media_buttons, Priority.LOW);
	}

	private bool on_hide_media_buttons () {
		revealer_timeout = 0;
		if (should_hide_controls) controls_revealer.set_reveal_child (false);

		return GLib.Source.REMOVE;
	}

	protected void on_click_gesture () {
		if (controls_revealer.reveal_child) {
			controls_revealer.reveal_child = false;
			revealer_timeout = 0;
		} else {
			on_reveal_media_buttons ();
		}
	}

	public Player (Gdk.Texture? texture = null, string? blurhash = null) {
		visualizer = new Audio.Visualizer (texture, blurhash) {
			vexpand = true,
			hexpand = true
		};

		var motion = new Gtk.EventControllerMotion () {
			propagation_phase = Gtk.PropagationPhase.BUBBLE
		};
		motion.motion.connect (on_motion);
		motion.leave.connect (on_leave);
		visualizer.add_controller (motion);

		var click_gesture = new Gtk.GestureClick () {
			button = Gdk.BUTTON_PRIMARY,
			propagation_phase = Gtk.PropagationPhase.BUBBLE
		};
		click_gesture.released.connect (on_click_gesture);
		visualizer.add_controller (click_gesture);

		player.bind_property ("level", visualizer, "level", BindingFlags.SYNC_CREATE);
		overlay.child = visualizer;

		on_reveal_media_buttons ();
	}

	public override void unmap () {
		if (revealer_timeout > 0) GLib.Source.remove (revealer_timeout);

		base.unmap ();
	}

	~Player () {
		debug ("Destroying AudioPlayer");
		player.destroy ();
	}
}
