using Gtk;

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

	public static EntityCache entity_cache;
	public static ImageCache image_cache;

	public static GLib.Regex bookwyrm_regex;
	public static GLib.Regex custom_emoji_regex;
	public static GLib.Regex rtl_regex;
	public static bool is_rtl;

	public static bool start_hidden = false;

	public static bool is_flatpak = false;

	public class Application : Adw.Application {

		public Dialogs.MainWindow? main_window { get; set; }
		public Dialogs.NewAccount? add_account_window { get; set; }

		public Gee.ArrayList<Tuba.Locale> locales { owned get { return generate_iso_639_1 (); } }

		// These are used for the GTK Inspector
		public Settings app_settings { get {return Tuba.settings; } }
		public AccountStore app_accounts { get {return Tuba.accounts; } }
		public Network app_network { get {return Tuba.network; } }
		public Streams app_streams { get {return Tuba.streams; } }

		public signal void refresh ();
		public signal void toast (string title);

		//  public CssProvider css_provider = new CssProvider ();
		//  public CssProvider zoom_css_provider = new CssProvider (); //FIXME: Zoom not working

		public const GLib.OptionEntry[] APP_OPTIONS = {
			{ "hidden", 0, 0, OptionArg.NONE, ref start_hidden, "Do not show main window on start", null },
			{ null }
		};

		private const GLib.ActionEntry[] APP_ENTRIES = {
			{ "about", about_activated },
			{ "compose", compose_activated },
			{ "back", back_activated },
			{ "refresh", refresh_activated },
			{ "search", search_activated },
			{ "quit", quit_activated },
			{ "back-home", back_home_activated },
			{ "scroll-page-down", scroll_view_page_down },
			{ "scroll-page-up", scroll_view_page_up }
		};

		construct {
			application_id = Build.DOMAIN;
			flags = ApplicationFlags.HANDLES_OPEN;
		}

		public static int main (string[] args) {
			try {
				var opt_context = new OptionContext ("- Options");
				opt_context.add_main_entries (APP_OPTIONS, null);
				opt_context.parse (ref args);
			}
			catch (GLib.OptionError e) {
				warning (e.message);
			}

			try {
				bookwyrm_regex = new GLib.Regex ("/book/\\d+/s/[-_a-z0-9]*", GLib.RegexCompileFlags.OPTIMIZE);
			} catch (GLib.RegexError e) {
				warning (e.message);
			}

			try {
				custom_emoji_regex = new GLib.Regex ("(:[a-zA-Z0-9_]{2,}:)", GLib.RegexCompileFlags.OPTIMIZE);
			} catch (GLib.RegexError e) {
				warning (e.message);
			}

			try {
				rtl_regex = new GLib.Regex (
					"[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]",
					GLib.RegexCompileFlags.OPTIMIZE,
					GLib.RegexMatchFlags.ANCHORED
				);
			} catch (GLib.RegexError e) {
				warning (e.message);
			}

			is_flatpak = GLib.Environment.get_variable ("FLATPAK_ID") != null
			|| GLib.File.new_for_path ("/.flatpak-info").query_exists ();

			Intl.setlocale (LocaleCategory.ALL, "");
			Intl.bindtextdomain (Build.GETTEXT_PACKAGE, Build.LOCALEDIR);
			Intl.textdomain (Build.GETTEXT_PACKAGE);

			app = new Application ();
			return app.run (args);
		}

		protected override void startup () {
			base.startup ();
			try {
				var lines = troubleshooting.split ("\n");
				foreach (unowned string line in lines) {
					message (line);
				}
				Adw.init ();

				#if !MISSING_GTKSOURCEVIEW
					GtkSource.init ();
				#endif

				settings = new Settings ();
				streams = new Streams ();
				network = new Network ();
				entity_cache = new EntityCache ();
				image_cache = new ImageCache () {
					maintenance_secs = 60 * 5
				};
				accounts = new SecretAccountStore ();
				accounts.init ();

				//  css_provider.load_from_resource (@"$(Build.RESOURCES)app.css");
				//  StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
				//  StyleContext.add_provider_for_display (Gdk.Display.get_default (), zoom_css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
			}
			catch (Error e) {
				var msg = "Could not start application: %s".printf (e.message);
				var dlg = inform (_("Error"), msg);
				dlg.present ();
				error (msg);
			}

			var style_manager = Adw.StyleManager.get_default ();
			ColorScheme color_scheme = (ColorScheme) settings.get_enum ("color-scheme");
			style_manager.color_scheme = color_scheme.to_adwaita_scheme ();

			set_accels_for_action ("app.about", {"F1"});
			set_accels_for_action ("app.compose", {"<Ctrl>T", "<Ctrl>N"});
			set_accels_for_action ("app.back", {"<Alt>BackSpace", "<Alt>Left", "Escape", "<Alt>KP_Left", "Pointer_DfltBtnPrev"});
			set_accels_for_action ("app.refresh", {"<Ctrl>R", "F5"});
			set_accels_for_action ("app.search", {"<Ctrl>F"});
			set_accels_for_action ("app.quit", {"<Ctrl>Q"});
			set_accels_for_action ("window.close", {"<Ctrl>W"});
			set_accels_for_action ("app.back-home", {"<Alt>Home"});
			set_accels_for_action ("app.scroll-page-down", {"Page_Down"});
			set_accels_for_action ("app.scroll-page-up", {"Page_Up"});
			add_action_entries (APP_ENTRIES, this);
		}

		protected override void activate () {
			present_window ();

			if (start_hidden) {
				start_hidden = false;
				return;
			}
			settings.delay ();
		}

		protected override void shutdown () {
			settings.apply ();
			base.shutdown ();
		}

		public override void open (File[] files, string hint) {
			foreach (File file in files) {
				string uri = file.get_uri ();
				if (add_account_window != null)
					add_account_window.redirect (uri);
				else
					warning (@"Received an unexpected uri to open: $uri");
				return;
			}
		}

		public void present_window (bool destroy_main = false) {
			if (accounts.saved.is_empty) {
				if (main_window != null && destroy_main)
					main_window.hide ();
				message ("Presenting NewAccount dialog");
				if (add_account_window == null)
					new Dialogs.NewAccount ();
				add_account_window.present ();
			} else {
				message ("Presenting MainWindow");
				if (main_window == null) {
					main_window = new Dialogs.MainWindow (this);
					is_rtl = Gtk.Widget.get_default_direction () == Gtk.TextDirection.RTL;
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

		string troubleshooting = "os: %s %s\nprefix: %s\nflatpak: %s\nversion: %s (%s)\ngtk: %u.%u.%u (%d.%d.%d)\nlibadwaita: %u.%u.%u (%d.%d.%d)\nlibsoup: %u.%u.%u (%d.%d.%d)%s".printf ( // vala-lint=line-length
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
			);

		void about_activated () {
			const string[] ARTISTS = {
				"Tobias Bernard"
			};

			const string[] DESIGNERS = {
				"Tobias Bernard"
			};

			const string[] DEVELOPERS = {
				"bleak_grey",
				"Evangelos \"GeopJr\" Paterakis"
			};

			const string COPYRIGHT = "© 2022 bleak_grey\n© 2022 Evangelos \"GeopJr\" Paterakis";

			var dialog = new Adw.AboutWindow () {
				transient_for = main_window,
				modal = true,

				application_icon = Build.DOMAIN,
				application_name = Build.NAME,
				version = Build.VERSION,
				support_url = Build.SUPPORT_WEBSITE,
				license_type = License.GPL_3_0_ONLY,
				copyright = COPYRIGHT,
				developers = DEVELOPERS,
				artists = ARTISTS,
				designers = DESIGNERS,
				debug_info = troubleshooting,
				debug_info_filename = @"$(Build.NAME).txt",
				// translators: Name <email@domain.com> or Name https://website.example
				translator_credits = _("translator-credits")
			};

			// For some obscure reason, const arrays produce duplicates in the credits.
			// Static functions seem to avoid this peculiar behavior.
			//  dialog.translator_credits = Build.TRANSLATOR != " " ? Build.TRANSLATOR : null;

			dialog.present ();

			GLib.Idle.add (() => {
				dialog.add_css_class (Tuba.Celebrate.get_celebration_css_class (new GLib.DateTime.now ()));
				return GLib.Source.REMOVE;
			});
		}

		public Adw.MessageDialog inform (string text, string? msg = null, Gtk.Window? win = app.main_window) {
			var dlg = new Adw.MessageDialog (
				win,
				text,
				msg
			);

			if (win != null)
				dlg.transient_for = win;

			dlg.add_response ("ok", _("OK"));

			return dlg;
		}

		public Adw.MessageDialog question (
			string text,
			string? msg = null,
			Gtk.Window? win = app.main_window,
			string yes_label = _("Yes"),
			Adw.ResponseAppearance yes_appearance = Adw.ResponseAppearance.DEFAULT,
			string no_label = _("Cancel"),
			Adw.ResponseAppearance no_appearance = Adw.ResponseAppearance.DEFAULT
		) {
			var dlg = new Adw.MessageDialog (
				win,
				text,
				msg
			);

			dlg.add_response ("no", no_label);
			dlg.set_response_appearance ("no", no_appearance);

			dlg.add_response ("yes", yes_label);
			dlg.set_response_appearance ("yes", yes_appearance);

			if (win != null)
				dlg.transient_for = win;
			return dlg;
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
