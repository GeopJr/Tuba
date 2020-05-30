using GLib;

public class Tootle.Settings : GLib.Settings {

	public int current_account { get; set; }
	public bool always_online { get; set; }
	public int char_limit { get; set; }
	public bool live_updates { get; set; }
	public bool live_updates_public { get; set; }
	public bool dark_theme { get; set; }

	public string watched_users { get; set; }
	public string watched_hashtags { get; set; }

	public int window_x { get; set; }
	public int window_y { get; set; }
	public int window_w { get; set; }
	public int window_h { get; set; }

	public Settings () {
		Object (schema_id: Build.DOMAIN);
		init ("current-account");
		init ("always-online");
		init ("char-limit");
		init ("live-updates");
		init ("live-updates-public");
		init ("dark-theme");

		init ("watched-users");
		init ("watched-hashtags");

		init ("window-x");
		init ("window-y");
		init ("window-w");
		init ("window-h");
	}

	void init (string key) {
		bind (key, this, key, SettingsBindFlags.DEFAULT);
	}

}
