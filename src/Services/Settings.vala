using GLib;

public class Tootle.Settings : GLib.Settings {

	public int current_account { get; set; }
	public bool dark_theme { get; set; }
	public bool autostart { get; set; }
	public bool work_in_background { get; set; }
	public API.Visibility default_post_visibility { get; set; }
	public int timeline_page_size { get; set; }
	public int post_text_size { get; set; }
	public bool live_updates { get; set; }
	public bool public_live_updates { get; set; }

	public string watched_users { get; set; }
	public string watched_hashtags { get; set; }

	public int window_x { get; set; }
	public int window_y { get; set; }
	public int window_w { get; set; }
	public int window_h { get; set; }

	public Settings () {
		Object (schema_id: Build.DOMAIN);
		init ("current-account");
		init ("dark-theme");
		init ("autostart");
		init ("work-in-background");
		init ("default-post-visibility");
		init ("timeline-page-size");
		init ("post-text-size");
		init ("live-updates");
		init ("public-live-updates");

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
