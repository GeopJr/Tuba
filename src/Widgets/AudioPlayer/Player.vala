public class Tuba.Widgets.Audio.Player : Adw.Bin {
	Audio.Stream player;
	Gtk.Overlay overlay;
	Audio.Visualizer visualizer;

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
		overlay.add_overlay (controls);

		player.bind_property ("current", controls, "current", BindingFlags.SYNC_CREATE);
		player.bind_property ("duration", controls, "duration", BindingFlags.SYNC_CREATE);
		player.ended.connect (on_ended);

		this.child = overlay;
	}

	private void on_ended () {
		this.playing = false;
	}

	public Player (Gdk.Texture? texture = null, string? blurhash = null) {
		visualizer = new Audio.Visualizer (texture, blurhash) {
			vexpand = true,
			hexpand = true
		};

		player.bind_property ("level", visualizer, "level", BindingFlags.SYNC_CREATE);
		overlay.child = visualizer;
	}

	~Player () {
		debug ("Destroying AudioPlayer");
		player.destroy ();
		//  visualizer.set_draw_func (null);
	}
}
