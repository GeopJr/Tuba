[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/preferences.ui")]
public class Tuba.Dialogs.Preferences : Adw.PreferencesWindow {
	struct NotificationTypeMute {
		public Adw.SwitchRow switch_widget;
		public string event;
	}

    [GtkChild] unowned Adw.ComboRow scheme_combo_row;
    [GtkChild] unowned Adw.ComboRow post_visibility_combo_row;
    [GtkChild] unowned Adw.ComboRow default_language_combo_row;
    [GtkChild] unowned Adw.ComboRow default_content_type_combo_row;
    [GtkChild] unowned Adw.SwitchRow work_in_background;
    [GtkChild] unowned Adw.SpinRow timeline_page_size;
    [GtkChild] unowned Adw.SwitchRow live_updates;
    [GtkChild] unowned Adw.SwitchRow public_live_updates;
    [GtkChild] unowned Adw.SwitchRow show_spoilers;
    [GtkChild] unowned Adw.SwitchRow show_preview_cards;
    [GtkChild] unowned Adw.SwitchRow larger_font_size;
    [GtkChild] unowned Adw.SwitchRow larger_line_height;
    [GtkChild] unowned Adw.SwitchRow scale_emoji_hover;
    [GtkChild] unowned Adw.SwitchRow strip_tracking;
    [GtkChild] unowned Adw.SwitchRow letterbox_media;
    [GtkChild] unowned Adw.SwitchRow media_viewer_expand_pictures;
    [GtkChild] unowned Adw.SwitchRow enlarge_custom_emojis;
    [GtkChild] unowned Adw.SwitchRow use_blurhash;
    [GtkChild] unowned Adw.SwitchRow group_push_notifications;
    [GtkChild] unowned Adw.SwitchRow advanced_boost_dialog;
    [GtkChild] unowned Adw.SwitchRow darken_images_on_dark_mode;

    [GtkChild] unowned Adw.SwitchRow new_followers_notifications_switch;
    [GtkChild] unowned Adw.SwitchRow new_follower_requests_notifications_switch;
    [GtkChild] unowned Adw.SwitchRow favorites_notifications_switch;
    [GtkChild] unowned Adw.SwitchRow mentions_notifications_switch;
    [GtkChild] unowned Adw.SwitchRow boosts_notifications_switch;
    [GtkChild] unowned Adw.SwitchRow poll_results_notifications_switch;
    [GtkChild] unowned Adw.SwitchRow edits_notifications_switch;

	NotificationTypeMute[] notification_type_mutes;

	void update_notification_mutes () {
		string[] res = {};

		foreach (var notification_type_mute in notification_type_mutes) {
			if (!notification_type_mute.switch_widget.active) res += notification_type_mute.event;
		}

		settings.muted_notification_types = res;
	}

	void update_notification_mutes_switches () {
		foreach (var notification_type_mute in notification_type_mutes) {
			notification_type_mute.switch_widget.active = !(notification_type_mute.event in settings.muted_notification_types);
		}
	}

	private bool lang_changed { get; set; default=false; }

	static construct {
		typeof (ColorSchemeListModel).ensure ();
	}

    construct {
        transient_for = app.main_window;

		post_visibility_combo_row.model = accounts.active.visibility_list;

        // Setup scheme combo row
        scheme_combo_row.selected = settings.get_enum ("color-scheme");

		uint default_visibility_index;
		if (
			accounts.active.visibility.has_key (settings.default_post_visibility)
			&& accounts.active.visibility_list.find (
				accounts.active.visibility[settings.default_post_visibility],
				out default_visibility_index
			)
		) {
			post_visibility_combo_row.selected = default_visibility_index;
		} else {
			post_visibility_combo_row.selected = 0;
			on_post_visibility_changed ();
		}

		if (accounts.active.supported_mime_types.n_items > 1) {
			default_content_type_combo_row.visible = true;
			setup_content_type_combo_row ();
		}

		setup_languages_combo_row ();
		setup_notification_mutes ();
		bind ();
		close_request.connect (on_window_closed);
    }

	void setup_notification_mutes () {
		notification_type_mutes = {
			{ new_followers_notifications_switch, InstanceAccount.KIND_FOLLOW },
			{ new_follower_requests_notifications_switch, InstanceAccount.KIND_FOLLOW_REQUEST },
			{ favorites_notifications_switch, InstanceAccount.KIND_FAVOURITE },
			{ mentions_notifications_switch, InstanceAccount.KIND_MENTION },
			{ boosts_notifications_switch, InstanceAccount.KIND_REBLOG},
			{ poll_results_notifications_switch, InstanceAccount.KIND_POLL},
			{ edits_notifications_switch, InstanceAccount.KIND_EDITED }
		};

		update_notification_mutes_switches ();
	}

    public static void open () {
        new Preferences ().show ();
    }

	void bind () {
        //  settings.bind ("dark-theme", dark_theme, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("work-in-background", work_in_background, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("timeline-page-size", timeline_page_size.adjustment, "value", SettingsBindFlags.DEFAULT);
        settings.bind ("live-updates", live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("public-live-updates", public_live_updates, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("show-spoilers", show_spoilers, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("show-preview-cards", show_preview_cards, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("larger-font-size", larger_font_size, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("larger-line-height", larger_line_height, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("scale-emoji-hover", scale_emoji_hover, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("strip-tracking", strip_tracking, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("letterbox-media", letterbox_media, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("media-viewer-expand-pictures", media_viewer_expand_pictures, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("enlarge-custom-emojis", enlarge_custom_emojis, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("use-blurhash", use_blurhash, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("group-push-notifications", group_push_notifications, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("advanced-boost-dialog", advanced_boost_dialog, "active", SettingsBindFlags.DEFAULT);
        settings.bind ("darken-images-on-dark-mode", darken_images_on_dark_mode, "active", SettingsBindFlags.DEFAULT);

		post_visibility_combo_row.notify["selected-item"].connect (on_post_visibility_changed);

		ulong dlcr_id = 0;
		dlcr_id = default_language_combo_row.notify["selected-item"].connect (() => {
			lang_changed = true;
			default_language_combo_row.disconnect (dlcr_id);
		});
	}

	[GtkCallback]
	private void on_scheme_changed () {
		var selected_item = (ColorSchemeListItem) scheme_combo_row.selected_item;
		var style_manager = Adw.StyleManager.get_default ();

		style_manager.color_scheme = selected_item.adwaita_scheme;
		settings.color_scheme = selected_item.color_scheme;
	}

	private void on_post_visibility_changed () {
		settings.default_post_visibility = (string) ((InstanceAccount.Visibility) post_visibility_combo_row.selected_item).id;
	}

	private void setup_languages_combo_row () {
		default_language_combo_row.list_factory = new Gtk.BuilderListItemFactory.from_resource (
			null,
			@"$(Build.RESOURCES)gtk/dropdown/language.ui"
		);
		default_language_combo_row.model = app.app_locales.list_store;

		var default_language = settings.default_language == "" ? "en" : settings.default_language;
		uint default_lang_index;
		if (
			app.app_locales.list_store.find_with_equal_func (
				new Tuba.Locales.Locale (default_language, null, null),
				Tuba.Locales.Locale.compare,
				out default_lang_index
			)
		) {
			default_language_combo_row.selected = default_lang_index;
		}
	}

	private void setup_content_type_combo_row () {
		default_content_type_combo_row.model = accounts.active.supported_mime_types;

		uint default_content_type_index;
		if (
			accounts.active.supported_mime_types.find_with_equal_func (
				new Tuba.InstanceAccount.StatusContentType (settings.default_content_type),
				Tuba.InstanceAccount.StatusContentType.compare,
				out default_content_type_index
			)
		) {
			default_content_type_combo_row.selected = default_content_type_index;
		}
	}

	private bool on_window_closed () {
		if (lang_changed) {
			var new_lang = ((Tuba.Locales.Locale) default_language_combo_row.selected_item).locale;
			if (settings.default_language != ((Tuba.Locales.Locale) default_language_combo_row.selected_item).locale) {

				new Request.PATCH ("/api/v1/accounts/update_credentials")
					.with_account (accounts.active)
					.with_form_data ("source[language]", new_lang)
					.then ((in_stream) => {
						var parser = Network.get_parser_from_inputstream (in_stream);
						var node = network.parse_node (parser);
						var updated = API.Account.from (node);

						settings.default_language = updated.source.language;
					})
					.exec ();
			}
		}

		if (default_content_type_combo_row.visible)
			settings.default_content_type = ((Tuba.InstanceAccount.StatusContentType) default_content_type_combo_row.selected_item).mime;

		update_notification_mutes ();
		return false;
	}
}

public class Tuba.ColorSchemeListModel : Object, ListModel {
	private Gee.ArrayList<ColorSchemeListItem> array = new Gee.ArrayList<ColorSchemeListItem> ();

	construct {
		array.add (new ColorSchemeListItem (SYSTEM));
		array.add (new ColorSchemeListItem (LIGHT));
		array.add (new ColorSchemeListItem (DARK));
	}

	public Object? get_item (uint position) requires (position < array.size) {
		return array.get ((int) position);
	}

	public Type get_item_type () {
		return typeof (ColorSchemeListItem);
	}

	public uint get_n_items () {
		return array.size;
	}

	public Object? get_object (uint position) {
		return get_item (position);
	}
}

public class Tuba.ColorSchemeListItem : Object {
	public ColorScheme color_scheme { get; construct; }
	public string name {
		owned get {
			return color_scheme.to_string ();
		}
	}
	public Adw.ColorScheme adwaita_scheme {
		get {
			return color_scheme.to_adwaita_scheme ();
		}
	}

	public ColorSchemeListItem (ColorScheme color_scheme) {
		Object (color_scheme: color_scheme);
	}
}
