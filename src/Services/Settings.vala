using GLib;

public class Tooth.Settings : GLib.Settings {

	public string active_account { get; set; }
	//  public bool dark_theme { get; set; }
	public bool autostart { get; set; }
	public bool work_in_background { get; set; }
	public int timeline_page_size { get; set; }
	public int post_text_size { get; set; }
	public bool live_updates { get; set; }
	public bool public_live_updates { get; set; }
	public bool show_spoilers { get; set; }
	public bool aggressive_resolving { get; set; }

	public Settings () {
		Object (schema_id: Build.DOMAIN);
		init ("active-account");
		//  init ("dark-theme");
		init ("autostart");
		init ("work-in-background");
		init ("timeline-page-size");
		init ("post-text-size");
		init ("live-updates");
		init ("public-live-updates");
		init ("show-spoilers");
		init ("aggressive-resolving");
	}

	void init (string key) {
		bind (key, this, key, SettingsBindFlags.DEFAULT);
	}

}
