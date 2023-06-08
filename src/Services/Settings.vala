using GLib;

public class Tuba.Settings : GLib.Settings {

	public string active_account { get; set; }
	public string default_language { get; set; default = "en"; }
	public ColorScheme color_scheme { get; set; }
	public string default_post_visibility { get; set; default = "public"; }
	public bool autostart { get; set; }
	public bool work_in_background { get; set; }
	public int timeline_page_size { get; set; }
	public bool live_updates { get; set; }
	public bool public_live_updates { get; set; }
	public bool show_spoilers { get; set; }
	public bool hide_preview_cards { get; set; }
	public bool larger_font_size { get; set; }
	public bool larger_line_height { get; set; }
	public bool aggressive_resolving { get; set; }
	public bool strip_tracking { get; set; }

	public Settings () {
		Object (schema_id: Build.DOMAIN);
		init ("active-account");
		init ("color-scheme");
		init ("default-post-visibility");
		init ("autostart");
		init ("work-in-background");
		init ("timeline-page-size");
		init ("live-updates");
		init ("public-live-updates");
		init ("show-spoilers");
		init ("hide-preview-cards");
		init ("larger-font-size");
		init ("larger-line-height");
		init ("aggressive-resolving");
		init ("strip-tracking");
	}

	void init (string key) {
		bind (key, this, key, SettingsBindFlags.DEFAULT);
	}
}

public enum Tuba.ColorScheme {
	SYSTEM,
	LIGHT,
	DARK;

	public string to_string () {
		switch (this) {
			case SYSTEM:
				// translators: Follow System's dark mode preference
				return _("Follow System");
			case LIGHT:
				// translators: Light mode theme
				return _("Light");
			case DARK:
				// translators: Dark mode theme
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