public class Tuba.Settings : GLib.Settings {
	public string active_account { get; set; }
	public string default_language { get; set; default = "en"; }
	public ColorScheme color_scheme { get; set; }
	public string default_post_visibility { get; set; default = "public"; }
	public bool work_in_background { get; set; }
	public int timeline_page_size { get; set; }
	public bool live_updates { get; set; }
	public bool public_live_updates { get; set; }
	public bool show_spoilers { get; set; }
	public bool show_preview_cards { get; set; }
	public bool larger_font_size { get; set; }
	public bool larger_line_height { get; set; }
	public bool scale_emoji_hover { get; set; }
	public bool aggressive_resolving { get; set; }
	public bool strip_tracking { get; set; }
	public bool letterbox_media { get; set; }
	public bool media_viewer_expand_pictures { get; set; }
	public bool enlarge_custom_emojis { get; set; }
	public string default_content_type { get; set; default = "text/plain"; }
	public bool use_blurhash { get; set; }
	public bool group_push_notifications { get; set; }
	public bool advanced_boost_dialog { get; set; }
	public bool reply_to_old_post_reminder { get; set; }
	public bool spellchecker_enabled { get; set; }

	public string[] muted_notification_types { get; set; default = {}; }
	private static string[] keys_to_init = {
		"active-account",
		"color-scheme",
		"default-post-visibility",
		"timeline-page-size",
		"live-updates",
		"public-live-updates",
		"show-spoilers",
		"show-preview-cards",
		"larger-font-size",
		"larger-line-height",
		"aggressive-resolving",
		"strip-tracking",
		"scale-emoji-hover",
		"letterbox-media",
		"media-viewer-expand-pictures",
		"enlarge-custom-emojis",
		"muted-notification-types",
		"default-content-type",
		"use-blurhash",
		"group-push-notifications",
		"advanced-boost-dialog",
		"reply-to-old-post-reminder",
		"spellchecker-enabled"
	};

	public Settings () {
		Object (schema_id: Build.DOMAIN);

		foreach (var key in keys_to_init) {
			init (key);
		}

		init ("work-in-background", true);
		changed.connect (on_changed);
	}

	string[] apply_instantly_keys = {};
	void init (string key, bool apply_instantly = false) {
		bind (key, this, key, SettingsBindFlags.DEFAULT);

		if (apply_instantly) apply_instantly_keys += key;
	}

	void on_changed (string key) {
		#if !DEV_MODE
			if (key in apply_instantly_keys) apply ();
		#endif
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
