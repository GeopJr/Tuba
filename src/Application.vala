namespace Tuba {
	public errordomain Oopsie {
		USER,
		PARSING,
		INSTANCE,
		INTERNAL
	}

	public static Application app;

	public static Settings settings;
	public static AccountStore accounts;
	public static Network network;
	public static Streams streams;
	public static NetworkMonitor network_monitor;

	//  public static EntityCache entity_cache;
	//  public static ImageCache image_cache;
	//  public static BlurhashCache blurhash_cache;

	public static GLib.Regex bookwyrm_regex;
	public static GLib.Regex custom_emoji_regex;
	public static GLib.Regex rtl_regex;
	public static bool is_rtl;

	public static bool start_hidden = false;
	public static bool is_flatpak = false;
	public static string cache_path;

	public static string default_locale;

	public class Application : Adw.Application {

		public GLib.ProxyResolver? proxy { get; set; default=null; }
		public Dialogs.MainWindow? main_window { get; set; }
		public Dialogs.NewAccount? add_account_window { get; set; }
		public bool is_mobile { get; set; default=false; }
		public bool is_online { get; private set; default=true; }

		public Locales app_locales { get; construct set; }

		// These are used for the GTK Inspector
		public Settings app_settings { get {return Tuba.settings; } }
		public AccountStore app_accounts { get {return Tuba.accounts; } }
		public Network app_network { get {return Tuba.network; } }
		public Streams app_streams { get {return Tuba.streams; } }

		public signal void refresh ();
		public signal void refresh_scheduled_statuses ();
		public signal void relationship_invalidated (API.Relationship new_relationship);
		public signal void remove_user_id (string user_id);
		public signal void toast (string title, uint timeout = 5);

		#if DEV_MODE
			public signal void dev_new_post (Json.Node node);
			public signal void dev_new_notification (Json.Node node);
		#endif

		//  public CssProvider css_provider = new CssProvider ();
		//  public CssProvider zoom_css_provider = new CssProvider (); //FIXME: Zoom not working

		public const GLib.OptionEntry[] APP_OPTIONS = {
			{ "hidden", 0, 0, OptionArg.NONE, ref start_hidden, N_("Do not show main window on start"), null },
			{ null }
		};

		private const GLib.ActionEntry[] APP_ENTRIES = {
			#if DEV_MODE
			 	// vala-lint=block-opening-brace-space-before
				{ "dev-only-window", dev_only_window_activated },
			#endif
			 // vala-lint=block-opening-brace-space-before
			{ "about", about_activated },
			{ "compose", compose_activated },
			{ "back", back_activated },
			{ "refresh", refresh_activated },
			{ "search", search_activated },
			{ "quit", quit_activated },
			{ "back-home", back_home_activated },
			{ "scroll-page-down", scroll_view_page_down },
			{ "scroll-page-up", scroll_view_page_up },
			{ "goto-notifications", goto_notifications },
			{ "open-status-url", open_status_url, "s" },
			{ "answer-follow-request", answer_follow_request, "(ssb)" },
			{ "follow-back", follow_back, "(ss)" },
			{ "reply-to-status-uri", reply_to_status_uri, "(ss)" },
			{ "remove-from-followers", remove_from_followers, "(ss)" },
			{ "open-preferences", open_preferences },
			{ "open-current-account-profile", open_current_account_profile },
			{ "open-announcements", open_announcements },
			{ "open-follow-requests", open_follow_requests },
			{ "open-mutes-blocks", open_mutes_blocks },
			{ "open-scheduled-posts", open_scheduled_posts },
			{ "open-draft-posts", open_draft_posts },
			{ "open-admin-dashboard", open_admin_dashboard },
			{ "open-last-fediwrapped", open_last_fediwrapped }
		};

		#if DEV_MODE
			private void dev_only_window_activated () {
				new Dialogs.Dev ().present (main_window);
			}
		#endif

		private void remove_from_followers (GLib.SimpleAction action, GLib.Variant? value) {
			if (value == null || accounts.active == null) return;

			accounts.active.remove_from_followers (
				value.get_child_value (0).get_string (),
				value.get_child_value (1).get_string ()
			);
		}

		private void reply_to_status_uri (GLib.SimpleAction action, GLib.Variant? value) {
			if (value == null || accounts.active == null) return;

			accounts.active.reply_to_status_uri (
				value.get_child_value (0).get_string (),
				value.get_child_value (1).get_string ()
			);
		}

		private void follow_back (GLib.SimpleAction action, GLib.Variant? value) {
			if (value == null || accounts.active == null) return;

			accounts.active.follow_back (
				value.get_child_value (0).get_string (),
				value.get_child_value (1).get_string ()
			);
		}

		private void goto_notifications () {
			Mastodon.Account.PLACE_NOTIFICATIONS.open_func (app.main_window);
		}

		private void open_status_url (GLib.SimpleAction action, GLib.Variant? value) {
			if (value == null || accounts.active == null) return;

			accounts.active.open_status_url (value.get_string ());
		}

		private void answer_follow_request (GLib.SimpleAction action, GLib.Variant? value) {
			if (value == null || accounts.active == null) return;

			accounts.active.answer_follow_request (
				value.get_child_value (0).get_string (),
				value.get_child_value (1).get_string (),
				value.get_child_value (2).get_boolean ()
			);
		}

		public void handle_web_ap (Uri uri) {
			if (accounts.active == null) return;

			accounts.active.resolve.begin (WebApHandler.from_uri (uri), (obj, res) => {
				try {
					accounts.active.resolve.end (res).open ();
				} catch (Error e) {
					string msg = @"Failed to resolve URL \"$uri\": $(e.message)";
					warning (msg);
					this.toast (msg);
				}
			});
		}

		private ShareHandler.ShareResult? to_share = null;
		public void handle_share () {
			if (to_share == null || accounts.active == null || accounts.active.instance_info == null) return;

			var status = new API.Status.empty ();
			status.content = to_share.text;
			if (to_share.cw != null) {
				status.spoiler_text = to_share.cw;
				status.sensitive = true;
			}

			new Dialogs.Compose (status);
			to_share = null;
		}

		construct {
			application_id = Build.DOMAIN;
			flags = ApplicationFlags.HANDLES_OPEN;

			add_main_option_entries (APP_OPTIONS);
			app_locales = new Tuba.Locales ();
		}

		public static int main (string[] args) {
			#if GSTREAMER
				Gst.init (ref args);
			#endif
			#if CLAPPER
				Clapper.init (ref args);
				GLib.Environment.set_variable ("CLAPPER_USE_PLAYBIN3", "1", false);
			#endif
			cache_path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S, GLib.Environment.get_user_cache_dir (), Build.NAME.down ());

			try {
				bookwyrm_regex = new GLib.Regex ("/book/\\d+(/?$|/s/[-_a-z0-9]*)", GLib.RegexCompileFlags.OPTIMIZE);
			} catch (GLib.RegexError e) {
				critical (e.message);
			}

			try {
				custom_emoji_regex = new GLib.Regex ("(:[a-zA-Z0-9_]{2,}:)", GLib.RegexCompileFlags.OPTIMIZE);
			} catch (GLib.RegexError e) {
				critical (e.message);
			}

			try {
				rtl_regex = new GLib.Regex (
					"[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]",
					GLib.RegexCompileFlags.OPTIMIZE,
					GLib.RegexMatchFlags.ANCHORED
				);
			} catch (GLib.RegexError e) {
				critical (e.message);
			}

			is_flatpak = GLib.Environment.get_variable ("FLATPAK_ID") != null
			|| GLib.File.new_for_path ("/.flatpak-info").query_exists ();

			Intl.setlocale (LocaleCategory.ALL, "");
			Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
			Intl.bind_textdomain_codeset (Build.GETTEXT_PACKAGE, "UTF-8");
			Intl.textdomain (Build.GETTEXT_PACKAGE);

			GLib.Environment.unset_variable ("GTK_THEME");
			#if WINDOWS || DARWIN
				GLib.Environment.set_variable ("SECRET_BACKEND", "file", false);
				if (GLib.Environment.get_variable ("SECRET_BACKEND") == "file")
					GLib.Environment.set_variable ("SECRET_FILE_TEST_PASSWORD", @"$(GLib.Environment.get_user_name ())$(Build.DOMAIN)", false);
			#endif

			if (GLib.Environment.get_variable ("GSK_RENDERER") == "gl") {
				GLib.Environment.set_variable ("GDK_DEBUG", "gl-no-fractional", false);
			}

			network_monitor = NetworkMonitor.get_default ();

			app = new Application ();
			return app.run (args);
		}

		private void on_network_change (bool online) {
			// We really need to avoid triggering it unnecessarily
			// wait 5 seconds before triggering it
			// also don't trust the 'online' status
			GLib.Timeout.add_once (5000, on_network_change_cb);
		}

		private void on_network_change_cb () {
			bool online = network_monitor.network_available;

			// Avoid triggering it as much as possible
			// as it causes websocket reconnects and
			// timeline refreshes
			if (is_online == online) return;
			is_online = online;
		}

		protected override void startup () {
			base.startup ();
			try {
				var lines = troubleshooting.split ("\n");
				foreach (unowned string line in lines) {
					debug (line);
				}
				Gtk.Window.set_default_icon_name (Build.DOMAIN);
				Adw.init ();
				GtkSource.init ();

				var t_default_locale = Gtk.get_default_language ().to_string ();
				if (t_default_locale == "c") {
					default_locale = "en-US";
				} else {
					if (t_default_locale.index_of_char ('-') != -1) {
						var tdl_parts = t_default_locale.split ("-", 2);
						t_default_locale = @"$(tdl_parts[0].down ())-$(tdl_parts[1].up ())";
					}
					default_locale = t_default_locale;
				}

				settings = new Settings ();
				streams = new Streams ();
				network = new Network ();
				//  entity_cache = new EntityCache ();
				//  image_cache = new ImageCache () {
				//  	maintenance_secs = 60 * 5
				//  };
				//  blurhash_cache = new BlurhashCache () {
				//  	maintenance_secs = 30
				//  };
				accounts = new SecretAccountStore ();
				accounts.init ();

				//  css_provider.load_from_resource (@"$(Build.RESOURCES)app.css");
				//  StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
				//  StyleContext.add_provider_for_display (Gdk.Display.get_default (), zoom_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
			} catch (Error e) {
				var msg = "Could not start application: %s".printf (e.message);
				error (msg);
			}

			var style_manager = Adw.StyleManager.get_default ();
			ColorScheme color_scheme = (ColorScheme) settings.get_enum ("color-scheme");
			style_manager.color_scheme = color_scheme.to_adwaita_scheme ();

			#if DEV_MODE
				set_accels_for_action ("app.dev-only-window", {"F2"});
			#endif
			set_accels_for_action ("app.about", {"F1"});
			set_accels_for_action ("app.open-preferences", {"<Ctrl>comma"});
			set_accels_for_action ("app.compose", {"<Ctrl>T", "<Ctrl>N"});
			set_accels_for_action ("app.back", {"<Alt>BackSpace", "<Alt>KP_Left"});
			set_accels_for_action ("app.refresh", {"<Ctrl>R", "F5"});
			set_accels_for_action ("app.search", {"<Ctrl>F"});
			set_accels_for_action ("app.quit", {"<Ctrl>Q"});
			set_accels_for_action ("window.close", {"<Ctrl>W"});
			set_accels_for_action ("app.back-home", {"<Alt>Home"});
			set_accels_for_action ("app.scroll-page-down", {"Page_Down"});
			set_accels_for_action ("app.scroll-page-up", {"Page_Up"});
			add_action_entries (APP_ENTRIES, this);

			if (settings.monitor_network)
				network_monitor.network_changed.connect (on_network_change);

			if (settings.proxy != "")
				on_proxy_change ();
			settings.notify ["proxy"].connect (on_proxy_notify);

			if (settings.analytics) app.update_analytics.begin ();
			app.update_contributors.begin ();
		}

		private void on_proxy_change (bool recover = false) {
			if (settings.proxy != "") {
				try {
					if (Uri.is_valid (settings.proxy, UriFlags.NONE)) {
						proxy = new GLib.SimpleProxyResolver (settings.proxy, null);
					}
				} catch (Error e) {
					// translators: Toast that pops up when
					//				an invalid proxy url has
					//				been provided in settings
					app.toast (_("Invalid Proxy URL"));
					warning (e.message);
					return;
				}
			} else {
				proxy = GLib.ProxyResolver.get_default ();
			}

			if (recover && add_account_window == null) {
				GLib.Timeout.add_once (5000, trigger_is_online_notify);
			}
		}

		private void trigger_is_online_notify () {
			this.notify_property ("is-online");
		}

		private void on_proxy_notify () {
			on_proxy_change (true);
		}

		private bool activated = false;
		protected override void activate () {
			activated = true;
			present_window ();

			if (start_hidden) {
				start_hidden = false;
				return;
			}

			settings.delay ();
		}

		protected override void shutdown () {
			#if !DEV_MODE
				settings.apply_all ();
			#endif
			network.flush_cache ();

			base.shutdown ();
		}

		public override void open (File[] files, string hint) {
			if (!activated) activate ();

			foreach (File file in files) {
				string unparsed_uri = file.get_uri ();

				try {
					Uri uri = Uri.parse (unparsed_uri, UriFlags.ENCODED);
					string scheme = uri.get_scheme ();

					switch (scheme) {
						case "tuba":
							if (add_account_window == null) {
								if (uri.get_host ().down () == "share") {
									to_share = ShareHandler.from_uri (uri);
									handle_share ();

									break;
								}

								// translators: the variable is a uri scheme like 'https'
								throw new Error.literal (-1, 1, _("'%s://' may only be used when adding a new account").printf (scheme));
							}
							add_account_window.redirect (uri);

							break;
						case "web+ap":
							// translators: the variable is a uri scheme like 'https'
							if (add_account_window != null)
								throw new Error.literal (-1, 2, _("'%s://' may not be used when adding a new account").printf (scheme));
							handle_web_ap (uri);

							break;
						default:
							// translators: the first variable is the app name ('Tuba'),
							//				the second one is a uri scheme like 'https'
							throw new Error.literal (-1, 3, _("%s does not accept '%s://'").printf (Build.NAME, scheme));
					}
				} catch (GLib.Error e) {
					string msg = @"Couldn't open $unparsed_uri: $(e.message)";
					warning (msg);
					var dlg = inform (_("Error"), msg);
					dlg.present (app.main_window);
				}
			}
		}

		public void present_window (bool destroy_main = false) {
			if (accounts.saved.is_empty) {
				if (main_window != null && destroy_main)
					main_window.hide ();
				debug ("Presenting NewAccount dialog");
				if (add_account_window == null)
					new Dialogs.NewAccount ();
				add_account_window.present ();
			} else {
				debug ("Presenting MainWindow");
				if (main_window == null) {
					is_rtl = Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL;
					main_window = new Dialogs.MainWindow (this);
				}
				if (!start_hidden) main_window.present ();
			}

			if (main_window != null)
				main_window.close_request.connect (on_window_closed);
		}

		public bool on_window_closed () {
			if (!settings.work_in_background || accounts.saved.is_empty) {
				main_window.hide_on_close = false;
			} else {
				main_window.hide_on_close = true;
			}

			return false;
		}

		void compose_activated () {
			if (accounts.active.instance_info == null) return;

			new Dialogs.Compose ();
		}

		void back_activated () {
			main_window.back ();
		}

		void search_activated () {
			main_window.open_view (new Views.Search ());
		}

		void quit_activated () {
			app.quit ();
		}

		void refresh_activated () {
			refresh ();
		}

		void back_home_activated () {
			main_window.go_back_to_start ();
		}

		void scroll_view_page_down () {
			main_window.scroll_view_page ();
		}

		void scroll_view_page_up () {
			main_window.scroll_view_page (true);
		}

		void open_preferences () {
			new Dialogs.Preferences ().present (main_window);
		}

		void open_current_account_profile () {
			accounts.active.open ();
			close_sidebar ();
		}

		public void open_announcements () {
			main_window.open_view (new Views.Announcements () {
				dismiss_all_announcements = true // dismiss all by default I guess
			});
			close_sidebar ();
			if (accounts.active != null) accounts.active.unread_announcements = 0;
		}

		public void open_follow_requests () {
			main_window.open_view (new Views.FollowRequests ());
			close_sidebar ();
			if (accounts.active != null) accounts.active.unreviewed_follow_requests = 0;
		}

		public void open_mutes_blocks () {
			main_window.open_view (new Views.MutesBlocks ());
			close_sidebar ();
		}

		public void open_scheduled_posts () {
			main_window.open_view (new Views.ScheduledStatuses ());
			close_sidebar ();
		}

		public void open_draft_posts () {
			main_window.open_view (new Views.DraftStatuses ());
			close_sidebar ();
		}

		public void open_admin_dashboard () {
			new Dialogs.Admin.Window ().present ();
		}

		public void open_last_fediwrapped () {
			accounts.active.open_latest_wrapped ();
		}

		private void close_sidebar () {
			var split_view = app.main_window.split_view;
			if (split_view.collapsed)
				split_view.show_sidebar = false;
		}

		string troubleshooting = "os: %s %s\nprefix: %s\nflatpak: %s\nversion: %s (%s)\ngtk: %u.%u.%u (%d.%d.%d)\nlibadwaita: %u.%u.%u (%d.%d.%d)\nlibsoup: %u.%u.%u (%d.%d.%d)%s\nlibspelling: %s\nClapper: %s\nGStreamer: %s".printf ( // vala-lint=line-length
				GLib.Environment.get_os_info ("NAME"), GLib.Environment.get_os_info ("VERSION"),
				Build.PREFIX,
				Tuba.is_flatpak.to_string (),
				Build.VERSION, Build.PROFILE,
				Gtk.get_major_version (), Gtk.get_minor_version (), Gtk.get_micro_version (),
				Gtk.MAJOR_VERSION, Gtk.MINOR_VERSION, Gtk.MICRO_VERSION,
				Adw.get_major_version (), Adw.get_minor_version (), Adw.get_micro_version (),
				Adw.MAJOR_VERSION, Adw.MINOR_VERSION, Adw.MICRO_VERSION,
				Soup.get_major_version (), Soup.get_minor_version (), Soup.get_micro_version (),
				Soup.MAJOR_VERSION, Soup.MINOR_VERSION, Soup.MICRO_VERSION,
				#if GTKSOURCEVIEW_5_7_1
					"\nlibgtksourceview: %u.%u.%u (%d.%d.%d)".printf (
						GtkSource.get_major_version (), GtkSource.get_minor_version (), GtkSource.get_micro_version (),
						GtkSource.MAJOR_VERSION, GtkSource.MINOR_VERSION, GtkSource.MICRO_VERSION
					)
				#else
					""
				#endif
				,
				#if LIBSPELLING
					"true"
				#else
					"false"
				#endif
				,
				#if CLAPPER
					@"$(Clapper.VERSION_S) ($(ClapperGtk.VERSION_S))"
				#else
					"false"
				#endif
				,
				#if GSTREAMER
					@"$(Gst.version_string ()) ($(Gst.VERSION_MAJOR).$(Gst.VERSION_MICRO).$(Gst.VERSION_MINOR).$(Gst.VERSION_NANO))"
				#else
					"false"
				#endif
			);

		void about_activated () {
			const string[] ARTISTS = {
				"Tobias Bernard",
				"Jakub Steiner"
			};

			const string[] DESIGNERS = {
				"Tobias Bernard",
				"Brage Fuglseth"
			};

			const string[] DEVELOPERS = {
				"bleak_grey",
				"Evangelos \"GeopJr\" Paterakis"
			};

			const string COPYRIGHT = "© 2022 bleak_grey\n© 2022 Evangelos \"GeopJr\" Paterakis";

			var dialog = new Adw.AboutDialog () {
				application_icon = Build.DOMAIN,
				application_name = Build.NAME,
				developer_name = "Evangelos “GeopJr” Paterakis",
				version = Build.VERSION,
				issue_url = Build.ISSUES_WEBSITE,
				support_url = Build.SUPPORT_WEBSITE,
				license_type = Gtk.License.GPL_3_0_ONLY,
				copyright = COPYRIGHT,
				developers = DEVELOPERS,
				artists = ARTISTS,
				designers = DESIGNERS,
				debug_info = troubleshooting,
				debug_info_filename = @"$(Build.NAME).txt",
				// translators: Name <email@domain.com> or Name https://website.example
				translator_credits = _("translator-credits")
			};

			// translators: Wiki pages / Guides
			dialog.add_link (_("Wiki"), Build.WIKI_WEBSITE);

			dialog.add_link (_("Translate"), Build.TRANSLATE_WEBSITE);
			dialog.add_link (_("Donate"), Build.DONATE_WEBSITE);

			// translators: Application metainfo for the app "Archives". <https://gitlab.gnome.org/GeopJr/Archives/>
			dialog.add_other_app ("dev.geopjr.Archives", _("Archives"), _("Create and view web archives"));
			// translators: Application metainfo for the app "Calligraphy". <https://gitlab.gnome.org/GeopJr/Calligraphy>
			dialog.add_other_app ("dev.geopjr.Calligraphy", _("Calligraphy"), _("Turn text into ASCII banners"));
			// translators: Application metainfo for the app "Collision". <https://github.com/GeopJr/Collision>
			dialog.add_other_app ("dev.geopjr.Collision", _("Collision"), _("Check hashes for your files"));

			// For some obscure reason, const arrays produce duplicates in the credits.
			// Static functions seem to avoid this peculiar behavior.
			//  dialog.translator_credits = Build.TRANSLATOR != " " ? Build.TRANSLATOR : null;

			dialog.present (main_window);

			GLib.Idle.add (() => {
				var style = Tuba.Celebrate.get_celebration_css_class (new GLib.DateTime.now ());
				if (style != "")
					dialog.add_css_class (style);
				return GLib.Source.REMOVE;
			});
		}

		public Adw.AlertDialog inform (string text, string? msg = null) {
			var dlg = new Adw.AlertDialog (
				text,
				msg
			);

			dlg.add_response ("ok", _("OK"));

			return dlg;
		}

		public struct QuestionButton {
			public string label;
			public Adw.ResponseAppearance appearance;
		}

		public struct QuestionButtons {
			public QuestionButton yes;
			public QuestionButton no;
		}

		public struct QuestionText {
			public string text;
			public bool use_markup;
		}

		public enum QuestionAnswer {
			YES,
			NO,
			CLOSE;

			public static QuestionAnswer from_string (string answer) {
				switch (answer.down ()) {
					case "yes":
						return YES;
					case "no":
						return NO;
					default:
						return CLOSE;
				}
			}

			public bool truthy () {
				return this == YES;
			}

			public bool falsy () {
				return this != YES;
			}
		}

		public async QuestionAnswer question (
			QuestionText title,
			QuestionText? msg = null,
			Gtk.Widget? win = app.main_window,
			QuestionButtons buttons = {
				{ _("Yes"), Adw.ResponseAppearance.DEFAULT },
				{ _("Cancel"), Adw.ResponseAppearance.DEFAULT }
			},
			Gtk.Widget? child = null,
			bool skip = false // skip the dialog, used for preferences to avoid duplicate code
		) {
			if (skip) return QuestionAnswer.YES;

			var dlg = new Adw.AlertDialog (
				title.text,
				msg == null ? null : msg.text
			);

			dlg.heading_use_markup = title.use_markup;
			if (msg != null) dlg.body_use_markup = msg.use_markup;

			if (child != null) dlg.extra_child = child;

			dlg.add_response ("no", buttons.no.label);
			dlg.set_response_appearance ("no", buttons.no.appearance);

			dlg.add_response ("yes", buttons.yes.label);
			dlg.set_response_appearance ("yes", buttons.yes.appearance);

			return QuestionAnswer.from_string (yield dlg.choose (win, null));
		}

		public string generate_analytics_object (bool pretty = false) {
			var generator = new Json.Generator () {
				pretty = pretty
			};
			var builder = new Json.Builder ();
			builder.begin_object ();

			builder.set_member_name ("accounts");
			builder.begin_array ();
			accounts.saved.foreach (e => {
				builder.add_string_value (e.uuid);
				return true;
			});
			builder.end_array ();

			builder.set_member_name ("analytics");
			builder.add_value (settings.to_debug_json ().get_root ());

			builder.end_object ();
			generator.set_root (builder.get_root ());
			return generator.to_data (null);
		}

		public async void update_contributors () {
			if (!settings.update_contributors) {
				// if updating contributors from the API is not enabled
				// but it has been enabled at some point in the past,
				// revert the contributors array to the default.
				// That will allow us to force clients that have
				// updated them manually in the past to use the bundled
				// array which might be more up-to-date.
				if (settings.last_contributors_update != null && settings.last_contributors_update != "") {
					settings.reset ("contributors");
					settings.last_contributors_update = "";
				}

				return;
			}

			bool can_update = false;
			GLib.DateTime now_utc = new GLib.DateTime.now_utc ();

			if (settings.last_contributors_update == null || settings.last_contributors_update == "") {
				can_update = true;
			} else {
				GLib.DateTime? then_utc = new GLib.DateTime.from_iso8601 (settings.last_contributors_update, null);
				if (then_utc == null) {
					can_update = true;
				} else {
					can_update = now_utc.difference (then_utc) > TimeSpan.DAY * 14;
				}
			}

			if (!can_update) return;
			var msg = new Request.GET ("https://api.tuba.geopjr.dev/v1/supporters");

			try {
				yield msg.await ();
				var parser = Network.get_parser_from_inputstream (msg.response_body);

				string[] new_contributors = {};
				Network.parse_array (parser, node => {
					if (node != null) {
						new_contributors += node.get_string ();
					}
				});

				settings.contributors = new_contributors;
				settings.last_contributors_update = now_utc.format_iso8601 ();
			} catch (Error e) {
				warning (@"Couldn't update contributors: $(e.code) $(e.message)");
			}
		}

		public async void update_analytics () {
			if (!settings.analytics) return;

			bool can_update = false;
			GLib.DateTime now_utc = new GLib.DateTime.now_utc ();

			if (settings.last_analytics_update == null || settings.last_analytics_update == "") {
				can_update = true;
			} else {
				GLib.DateTime? then_utc = new GLib.DateTime.from_iso8601 (settings.last_analytics_update, null);
				if (then_utc == null) {
					can_update = true;
				} else {
					can_update = now_utc.difference (then_utc) > TimeSpan.DAY * 14;
				}
			}

			if (!can_update) return;
			var msg = new Request.POST ("https://api.tuba.geopjr.dev/v1/analytics")
				.body ("application/json", new Bytes.take (generate_analytics_object ().data));

			try {
				yield msg.await ();
				settings.last_analytics_update = now_utc.format_iso8601 ();
			} catch (Error e) {
				warning (@"Couldn't update analytics: $(e.code) $(e.message)");
			}

		}
	}

	public static void toggle_css (Gtk.Widget wdg, bool state, string style) {
		if (state) {
			wdg.add_css_class (style);
		} else {
			wdg.remove_css_class (style);
		}
	}
}
