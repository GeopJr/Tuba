[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/audiocontrols.ui")]
public class Tuba.Widgets.Audio.Controls : Gtk.Box {
	[GtkChild] unowned Gtk.Adjustment time_adjustment;
	[GtkChild] unowned Gtk.Button play_button;
	[GtkChild] unowned Gtk.Label time_label;
	[GtkChild] unowned Gtk.Label duration_label;
	[GtkChild] unowned Gtk.VolumeButton volume_button;

	public signal void state_button_clicked ();
	public double volume { get; set; default=1.0; }
	public double progress { get; set; default=0.0; }

	private bool _playing = false;
	public bool playing {
		get { return _playing; }
		set {
			if (value) {
				play_button.icon_name = "media-playback-pause-symbolic";
				// translators: Media play bar play button tooltip
				play_button.tooltip_text = _("Stop");
			} else {
				play_button.icon_name = "media-playback-start-symbolic";
				// translators: Media play bar play button tooltip
				play_button.tooltip_text = _("Play");
			}

			_playing = value;
		}
	}

	private int64 _duration = 0;
	public int64 duration {
		get {
			return _duration;
		}
		set {
			_duration = value;
			duration_label.label = nanoseconds_to_string (value);
			update_scale ();
		}
	}

	private int64 _current = 0;
	public int64 current {
		get {
			return _current;
		}
		set {
			int64 safe_val = int64.min (value, _duration);
			_current = safe_val;
			time_label.label = nanoseconds_to_string (safe_val);
			update_scale ();
		}
	}

	private string nanoseconds_to_string (int64 nanoseconds) {
		double seconds_total = (double) nanoseconds / (1000 * 1000 * 1000);

		int seconds = (int) (seconds_total % 60);
		int minutes = (int) ((seconds_total / 60) % 60);
		int hours = (int) ((seconds_total / (60 * 60)) % 24);

		string seconds_prefix = seconds > 9 ? "" : "0";
		string minutes_prefix = minutes > 9 ? "" : "0";
		string hours_s = hours > 0 ? @"$hours:" : "";

		return @"$hours_s$minutes_prefix$minutes:$seconds_prefix$seconds";
	}

	private void update_scale () {
		if (this.duration == 0) return;

		GLib.SignalHandler.block (time_adjustment, time_adjustment_changed_id);
		time_adjustment.value = (double)this.current / (double)this.duration * 10;
		GLib.SignalHandler.unblock (time_adjustment, time_adjustment_changed_id);
	}

	public void update_playing_button (bool playing) {
		if (playing) {
			play_button.icon_name = "media-playback-pause-symbolic";
			// translators: Media play bar play button tooltip
			play_button.tooltip_text = _("Stop");
		} else {
			play_button.icon_name = "media-playback-start-symbolic";
			// translators: Media play bar play button tooltip
			play_button.tooltip_text = _("Play");
		}
	}

	ulong time_adjustment_changed_id;
	construct {
		volume_button.bind_property ("value", this, "volume", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
		time_adjustment_changed_id = time_adjustment.value_changed.connect (time_adjustment_changed);

	}

	private void time_adjustment_changed () {
		if (time_adjustment.value == this.progress) return;

		this.progress = time_adjustment.value;
	}

	[GtkCallback] private void play_button_clicked () {
		this.playing = !this.playing;
	}

	~Controls () {
		debug ("Destroying AudioControls");
	}
}
