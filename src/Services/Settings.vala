using GLib;

public class Tooth.Settings : GLib.Settings {

	public string active_account { get; set; }
	public ColorScheme color_scheme { get; set; }
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
		init ("color-scheme");
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

public enum Tooth.ColorScheme {
	SYSTEM,
	LIGHT,
	DARK;

	public string to_string () {
		switch (this) {
			case SYSTEM:
				return _("Follow System");
			case LIGHT:
				return _("Light");
			case DARK:
				return _("Dark");
			default:
				assert_not_reached ();
		}
	}

	public Adw.ColorScheme to_adwaita_scheme () {
		switch (this) {
			case SYSTEM:
				return DEFAULT;
			case LIGHT:
				return FORCE_LIGHT;
			case DARK:
				return FORCE_DARK;
			default:
				assert_not_reached ();
		}
	}
}