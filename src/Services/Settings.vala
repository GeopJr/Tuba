public class Tuba.Settings : GLib.Settings {
	public class Account : GLib.Settings {
		public string default_language { get; set; default = "en"; }
		public string default_post_visibility { get; set; default = "public"; }
		public string default_content_type { get; set; default = "text/plain"; }
		public bool account_suggestions { get; set; default = true; }
		public string[] muted_notification_types { get; set; default = {}; }
		public string[] recently_used_custom_emojis { get; set; default = {}; }
		public string[] notification_filters { get; set; default = {}; }

		private static string[] keys_to_init = {
			"default-post-visibility",
			"muted-notification-types",
			"default-content-type",
			"recently-used-custom-emojis",
			"notification-filters",
			"account-suggestions"
		};

		public Account (string id) {
			Object (schema_id: @"$(Build.DOMAIN).Account", path: @"/$(Build.DOMAIN.replace (".", "/"))/accounts/$id/");
			this.delay ();

			foreach (var key in keys_to_init) {
				init (key);
			}
		}

		void init (string key) {
			bind (key, this, key, SettingsBindFlags.DEFAULT);
		}
	}

	private Account active_account_settings { get; set; }
	private string _active_account = "";
	public string active_account {
		get {
			return _active_account;
		}

		set {
			_active_account = value;
			if (active_account_settings != null) active_account_settings.apply ();
			active_account_settings = new Account (value);
		}
	}

	public string default_language {
		get {
			return active_account_settings.default_language;
		}

		set {
			active_account_settings.default_language = value;
		}
	}

	public string default_post_visibility {
		get {
			return active_account_settings.default_post_visibility;
		}

		set {
			active_account_settings.default_post_visibility = value;
		}
	}

	public string default_content_type {
		get {
			return active_account_settings.default_content_type;
		}

		set {
			active_account_settings.default_content_type = value;
		}
	}

	public bool account_suggestions {
		get {
			return active_account_settings.account_suggestions;
		}

		set {
			active_account_settings.account_suggestions = value;
		}
	}

	public string[] muted_notification_types {
		get {
			return active_account_settings.muted_notification_types;
		}

		set {
			active_account_settings.muted_notification_types = value;
		}
	}

	public string[] recently_used_custom_emojis {
		get {
			return active_account_settings.recently_used_custom_emojis;
		}

		set {
			active_account_settings.recently_used_custom_emojis = value;
		}
	}

	public string[] notification_filters {
		get {
			return active_account_settings.notification_filters;
		}

		set {
			active_account_settings.notification_filters = value;
		}
	}

	public ColorScheme color_scheme { get; set; }
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
	public bool use_blurhash { get; set; }
	public bool group_push_notifications { get; set; }
	public bool advanced_boost_dialog { get; set; }
	public bool reply_to_old_post_reminder { get; set; }
	public bool copy_private_link_reminder { get; set; }
	public bool spellchecker_enabled { get; set; }
	public bool darken_images_on_dark_mode { get; set; }
	public double media_viewer_last_used_volume { get; set; }
	public bool monitor_network { get; set; }
	public string proxy { get; set; }
	public bool dim_trivial_notifications { get; set; }
	public bool analytics { get; set; }
	public bool update_contributors { get; set; }
	public string last_analytics_update { get; set; }
	public string last_contributors_update { get; set; }
	public string[] contributors { get; set; default = {}; }

	private static string[] keys_to_init = {
		"active-account",
		"color-scheme",
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
		"use-blurhash",
		"group-push-notifications",
		"advanced-boost-dialog",
		"reply-to-old-post-reminder",
		"copy-private-link-reminder",
		"spellchecker-enabled",
		"darken-images-on-dark-mode",
		"media-viewer-last-used-volume",
		"monitor-network",
		"proxy",
		"dim-trivial-notifications",
		"analytics",
		"update-contributors"
	};

	public Settings () {
		Object (schema_id: Build.DOMAIN);

		foreach (var key in keys_to_init) {
			init (key);
		}

		init ("work-in-background", true);
		init ("last-analytics-update", true);
		init ("last-contributors-update", true);
		init ("contributors", true);
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

	public void apply_all () {
		if (active_account_settings != null) active_account_settings.apply ();

		this.apply ();
	}

	private string[] sensitive_keys = {
		"proxy",
		"active-account",
		"last-analytics-update",
		"last-contributors-update",
		"contributors"
	};

	public Json.Builder to_debug_json () {
		var builder = new Json.Builder ();
		builder.begin_object ();

		foreach (string key in keys_to_init) {
			if (key in sensitive_keys) continue;

			var val = Value (Type.STRING);
			this.get_property (key, ref val);

			builder.set_member_name (key);
			builder.add_string_value ((string) val);
		}

		builder.end_object ();
		return builder;
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
