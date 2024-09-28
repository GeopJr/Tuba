[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/preferences.ui")]
public class Tuba.Dialogs.Preferences : Adw.PreferencesDialog {
	~Preferences () {
		debug ("Destroying Preferences");
	}

	class FilterRow : Adw.ExpanderRow {
		private API.Filters.Filter filter;
		private weak Dialogs.Preferences win;
		public signal void filter_deleted (FilterRow self);

		~FilterRow () {
			labels = {};
		}

		public FilterRow (API.Filters.Filter filter, Dialogs.Preferences win) {
			this.filter = filter;
			this.win = win;
			this.activatable = false;

			var delete_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
				css_classes = { "circular", "flat", "error" },
				tooltip_text = _("Delete"),
				valign = Gtk.Align.CENTER
			};
			delete_btn.clicked.connect (on_delete);
			this.add_suffix (delete_btn);

			var edit_btn = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
				css_classes = { "circular", "flat" },
				tooltip_text = _("Edit"),
				valign = Gtk.Align.CENTER
			};
			edit_btn.clicked.connect (on_edit);
			this.add_suffix (edit_btn);

			populate_from_filter ();
		}

		Gtk.Widget[] labels = {};
		private void populate_from_filter () {
			this.title = this.filter.title;
			this.subtitle = GLib.ngettext ("%d keyword", "%d keywords", (ulong) this.filter.keywords.size).printf (this.filter.keywords.size);

			foreach (var label in labels) {
				this.remove (label.get_parent ());
			}
			labels = {};

			this.filter.keywords.@foreach (e => {
				var label = new Gtk.Label (e.keyword) {
					ellipsize = Pango.EllipsizeMode.END,
					halign = Gtk.Align.START,
					margin_bottom = 8,
					margin_end = 8,
					margin_start = 8,
					margin_top = 8
				};
				labels += label;
				this.add_row (label);
				return true;
			});
		}

		private void on_edit () {
			var dlg = new Dialogs.FilterEdit (win, filter);
			dlg.saved.connect (on_save);
		}

		private void on_save (API.Filters.Filter filter) {
			this.filter = filter;
			populate_from_filter ();
		}

		private void on_delete () {
			app.question.begin (
				// translators: the variable is a filter name
				{_("Delete %s?").printf (filter.title), false},
				null,
				this.win,
				{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						new Request.DELETE (@"/api/v2/filters/$(filter.id)")
							.with_account (accounts.active)
							.then (() => {
								filter_deleted (this);
							})
							.on_error ((code, message) => {
								// translators: the variable is an error message
								win.add_toast (new Adw.Toast (_("Couldn't delete filter: %s").printf (message)) {
									timeout = 0
								});
								warning (@"Couldn't delete filter $(this.filter.id): $code $message");
							})
							.exec ();
					}
				}
			);
		}
	}

	struct NotificationTypeMute {
		public Adw.SwitchRow switch_widget;
		public string event;
	}

	[GtkChild] unowned Adw.ComboRow post_visibility_combo_row;
	[GtkChild] unowned Adw.ComboRow default_language_combo_row;
	[GtkChild] unowned Adw.ComboRow default_content_type_combo_row;
	[GtkChild] unowned Adw.SwitchRow work_in_background;
	[GtkChild] unowned Adw.SpinRow timeline_page_size;
	[GtkChild] unowned Adw.SwitchRow live_updates;
	[GtkChild] unowned Adw.SwitchRow public_live_updates;
	[GtkChild] unowned Adw.SwitchRow show_spoilers;
	[GtkChild] unowned Adw.SwitchRow larger_font_size;
	[GtkChild] unowned Adw.SwitchRow larger_line_height;
	[GtkChild] unowned Adw.SwitchRow strip_tracking;
	[GtkChild] unowned Adw.SwitchRow letterbox_media;
	[GtkChild] unowned Adw.SwitchRow enlarge_custom_emojis;
	[GtkChild] unowned Adw.SwitchRow group_push_notifications;
	[GtkChild] unowned Adw.SwitchRow advanced_boost_dialog;
	[GtkChild] unowned Adw.SwitchRow darken_images_on_dark_mode;
	[GtkChild] unowned Adw.SwitchRow reply_to_old_post_reminder;
	[GtkChild] unowned Adw.EntryRow proxy_entry;
	[GtkChild] unowned Adw.SwitchRow dim_trivial_notifications;

	[GtkChild] unowned Adw.SwitchRow new_followers_notifications_switch;
	[GtkChild] unowned Adw.SwitchRow new_follower_requests_notifications_switch;
	[GtkChild] unowned Adw.SwitchRow favorites_notifications_switch;
	[GtkChild] unowned Adw.SwitchRow mentions_notifications_switch;
	[GtkChild] unowned Adw.SwitchRow boosts_notifications_switch;
	[GtkChild] unowned Adw.SwitchRow poll_results_notifications_switch;
	[GtkChild] unowned Adw.SwitchRow edits_notifications_switch;

	[GtkChild] unowned Adw.PreferencesGroup filtered_notifications_group;
	[GtkChild] unowned Adw.SwitchRow filter_notifications_following_switch;
	[GtkChild] unowned Adw.SwitchRow filter_notifications_follower_switch;
	[GtkChild] unowned Adw.SwitchRow filter_notifications_new_account_switch;
	[GtkChild] unowned Adw.SwitchRow filter_notifications_dm_switch;

	//  [GtkChild] unowned Adw.PreferencesPage filters_page;
	[GtkChild] unowned Adw.PreferencesGroup keywords_group;

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
	private bool privacy_changed { get; set; default=false; }

	construct {
		proxy_entry.text = settings.proxy;
		post_visibility_combo_row.model = accounts.active.visibility_list;

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
		setup_notification_filters ();
		setup_filters ();
		bind ();
		closed.connect (on_window_closed);
	}

	private Gee.HashMap<Adw.SwitchRow, bool>? notification_filter_policy_status = null;
	void setup_notification_filters () {
		if (!accounts.active.probably_has_notification_filters) return;

		new Request.GET ("/api/v1/notifications/policy")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				if (node == null) return;

				filtered_notifications_group.visible = true;
				var policies = API.NotificationFilter.Policy.from (node);

				notification_filter_policy_status = new Gee.HashMap<Adw.SwitchRow, bool> ();
				notification_filter_policy_status.set (filter_notifications_following_switch, policies.filter_not_following);
				notification_filter_policy_status.set (filter_notifications_follower_switch, policies.filter_not_followers);
				notification_filter_policy_status.set (filter_notifications_new_account_switch, policies.filter_new_accounts);
				notification_filter_policy_status.set (filter_notifications_dm_switch, policies.filter_private_mentions);

				notification_filter_policy_status.@foreach (entry => {
					((Adw.SwitchRow) entry.key).active = (bool) entry.value;

					return true;
				});
			})
			.on_error ((code, message) => {
				if (code == 404) {
					accounts.active.probably_has_notification_filters = false;
				} else {
					warning (@"Error while trying to get notification policy: $code $message");
				}
			})
			.exec ();
	}

	void setup_filters () {
		// Only support v2 filters
		new Request.GET ("/api/v2/filters")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				Network.parse_array (parser, node => {
					var row = new FilterRow (API.Filters.Filter.from (node), this);
					row.filter_deleted.connect (on_filter_delete);
					keywords_group.add (row);
				});
			})
			.exec ();
	}

	void on_filter_delete (FilterRow row) {
		keywords_group.remove (row);
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

	ulong dlcr_id = 0;
	void bind () {
		//  settings.bind ("dark-theme", dark_theme, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("work-in-background", work_in_background, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("timeline-page-size", timeline_page_size.adjustment, "value", SettingsBindFlags.DEFAULT);
		settings.bind ("live-updates", live_updates, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("public-live-updates", public_live_updates, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("show-spoilers", show_spoilers, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("larger-font-size", larger_font_size, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("larger-line-height", larger_line_height, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("strip-tracking", strip_tracking, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("letterbox-media", letterbox_media, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("enlarge-custom-emojis", enlarge_custom_emojis, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("group-push-notifications", group_push_notifications, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("advanced-boost-dialog", advanced_boost_dialog, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("darken-images-on-dark-mode", darken_images_on_dark_mode, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("reply-to-old-post-reminder", reply_to_old_post_reminder, "active", SettingsBindFlags.DEFAULT);
		settings.bind ("dim-trivial-notifications", dim_trivial_notifications, "active", SettingsBindFlags.DEFAULT);

		post_visibility_combo_row.notify["selected-item"].connect (on_post_visibility_changed);
		dlcr_id = default_language_combo_row.notify["selected-item"].connect (dlcr_cb);
	}

	private void dlcr_cb () {
		lang_changed = true;
		default_language_combo_row.disconnect (dlcr_id);
	}

	[GtkCallback]
	private void add_keyword_row () {
		var dlg = new Dialogs.FilterEdit (this);
		dlg.saved.connect (on_filter_save);
	}

	private void on_filter_save (API.Filters.Filter filter) {
		var row = new FilterRow (filter, this);
		row.filter_deleted.connect (on_filter_delete);
		keywords_group.add (row);
	}

	private void on_post_visibility_changed () {
		settings.default_post_visibility = (string) ((InstanceAccount.Visibility) post_visibility_combo_row.selected_item).id;
		privacy_changed = true;
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

	private void on_window_closed () {
		if (notification_filter_policy_status != null) {
			bool changed = false;
			notification_filter_policy_status.@foreach (entry => {
				if (((Adw.SwitchRow) entry.key).active != (bool) entry.value) {
					changed = true;
					return false;
				}

				return true;
			});

			if (changed) {
				var builder = new Json.Builder ();
				builder.begin_object ();

				builder.set_member_name ("filter_not_following");
				builder.add_boolean_value (filter_notifications_following_switch.active);

				builder.set_member_name ("filter_not_followers");
				builder.add_boolean_value (filter_notifications_follower_switch.active);

				builder.set_member_name ("filter_new_accounts");
				builder.add_boolean_value (filter_notifications_new_account_switch.active);

				builder.set_member_name ("filter_private_mentions");
				builder.add_boolean_value (filter_notifications_dm_switch.active);

				builder.end_object ();

				new Request.PUT ("/api/v1/notifications/policy")
					.with_account (accounts.active)
					.body_json (builder)
					.exec ();
			}

			notification_filter_policy_status.clear ();
		}

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

		if (privacy_changed && settings.default_post_visibility != "direct") {
			new Request.PATCH ("/api/v1/accounts/update_credentials")
				.with_account (accounts.active)
				.with_form_data ("source[privacy]", settings.default_post_visibility)
				.exec ();
		}

		if (default_content_type_combo_row.visible)
			settings.default_content_type = ((Tuba.InstanceAccount.StatusContentType) default_content_type_combo_row.selected_item).mime;

		update_notification_mutes ();

		if (proxy_entry.text != "") {
			try {
				if (Uri.is_valid (proxy_entry.text, UriFlags.NONE))
					settings.proxy = proxy_entry.text;
			} catch (Error e) {
				// translators: Toast that pops up when
				//				an invalid proxy url has
				//				been provided in settings
				app.toast (_("Invalid Proxy URL"));
				warning (e.message);
			}
		} else if (settings.proxy != "") {
			settings.proxy = "";
		}
	}
}
