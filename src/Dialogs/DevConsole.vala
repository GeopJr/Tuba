// DEV ONLY WINDOW
// Do not translate
public class Tuba.Dialogs.Dev : Adw.PreferencesDialog {
	public class WindowSize : Object {
		public int w { get; construct set; }
		public int h { get; construct set; }
		public string name {
			owned get {
				return @"$(w)x$(h)";
			}
		}

		public WindowSize (int w, int h) {
			Object (w: w, h: h);
		}
	}

	public GLib.ListStore ws_cr_model;

	WindowSize[] window_sizes = {
		new WindowSize (624, 351),
		new WindowSize (800, 450),
		new WindowSize (1024, 576),
		new WindowSize (1200, 675),
		new WindowSize (1600, 900),
		new WindowSize (360, 654),
		new WindowSize (720, 360),
		new WindowSize (1000, 700),
		new WindowSize (800, 566)
	};

	construct {
		var general_settings = new Adw.PreferencesPage ();
		var appearance_group = new Adw.PreferencesGroup () {
			title = "Appearance"
		};

		var color_scheme_sr = new Adw.SwitchRow () {
			title = "Dark Mode",
			active = Adw.StyleManager.get_default ().dark
		};
		color_scheme_sr.notify["active"].connect (() => update_color_scheme (color_scheme_sr.active));

		Gtk.SignalListItemFactory signallistitemfactory = new Gtk.SignalListItemFactory ();
		signallistitemfactory.bind.connect (ws_cr_bind);

		ws_cr_model = new GLib.ListStore (typeof (WindowSize));
		ws_cr_model.splice (0, 0, window_sizes);

		var window_size_cr = new Adw.ComboRow () {
			title = "Window Size",
			model = ws_cr_model,
			factory = signallistitemfactory
		};
		window_size_cr.notify["selected"].connect (() => update_window_size ((WindowSize) window_size_cr.selected_item));

		appearance_group.add (color_scheme_sr);
		appearance_group.add (window_size_cr);
		general_settings.add (appearance_group);

		var counters_group = new Adw.PreferencesGroup () {
			title = "Counters"
		};

		var home_badge_row = new Adw.SpinRow.with_range (0, 200, 1.0) {
			title = "Home",
			value = Tuba.Mastodon.Account.PLACE_HOME.badge,

		};
		home_badge_row.notify["value"].connect (() => update_home_badge (home_badge_row.value));

		var notification_badge_row = new Adw.SpinRow.with_range (0, 200, 1.0) {
			title = "Notifications",
			value = Tuba.Mastodon.Account.PLACE_NOTIFICATIONS.badge,

		};
		notification_badge_row.notify["value"].connect (() => update_notification_badge (notification_badge_row.value));

		var unread_announcements_row = new Adw.SpinRow.with_range (0, 200, 1.0) {
			title = "Unread Announcements",
			value = accounts.active.unread_announcements,

		};
		unread_announcements_row.notify["value"].connect (() => update_unread_announcements (unread_announcements_row.value));

		var unreviewed_follow_requests_row = new Adw.SpinRow.with_range (0, 200, 1.0) {
			title = "Unreviewed Follow Requests",
			value = accounts.active.unreviewed_follow_requests,

		};
		unreviewed_follow_requests_row.notify["value"].connect (() => update_unreviewd_fr (unreviewed_follow_requests_row.value));

		counters_group.add (home_badge_row);
		counters_group.add (notification_badge_row);
		counters_group.add (unread_announcements_row);
		counters_group.add (unreviewed_follow_requests_row);
		general_settings.add (counters_group);

		var json_group = new Adw.PreferencesGroup () {
			title = "Entities"
		};

		var status_entry_row = new Adw.EntryRow () {
			title = "Prepend Status from JSON",
			show_apply_button = true
		};
		status_entry_row.apply.connect (() => new_post (status_entry_row.text));

		var notification_entry_row = new Adw.EntryRow () {
			title = "Prepend Notification from JSON",
			show_apply_button = true
		};
		notification_entry_row.apply.connect (() => new_notification (notification_entry_row.text));

		var profile_entry_row = new Adw.EntryRow () {
			title = "Open Profile from JSON",
			show_apply_button = true
		};
		profile_entry_row.apply.connect (() => open_account (profile_entry_row.text));

		var annual_report_entry_row = new Adw.EntryRow () {
			title = "View an Annual Report from JSON",
			show_apply_button = true
		};
		annual_report_entry_row.apply.connect (() => view_annual_report (annual_report_entry_row.text));

		json_group.add (status_entry_row);
		json_group.add (notification_entry_row);
		json_group.add (profile_entry_row);
		json_group.add (annual_report_entry_row);
		general_settings.add (json_group);

		this.add (general_settings);
	}

	private void open_account (string? json) {
		if (json == null || json.length == 0) return;

		var parser = new Json.Parser ();
		parser.load_from_data (json, -1);
		API.Account acc = (API.Account) Entity.from_json (typeof (API.Account), parser.steal_root ());

		app.main_window.open_view (new Views.Profile (acc));
	}

	private void view_annual_report (string? json) {
		if (json == null || json.length == 0) return;

		var parser = new Json.Parser ();
		parser.load_from_data (json, -1);
		API.AnnualReports.from (parser.steal_root ()).open ();
	}

	private void new_notification (string? json) {
		if (json == null || json.length == 0) return;

		var parser = new Json.Parser ();
		parser.load_from_data (json, -1);
		app.dev_new_notification (parser.steal_root ());
	}

	private void new_post (string? json) {
		if (json == null || json.length == 0) return;

		var parser = new Json.Parser ();
		parser.load_from_data (json, -1);
		app.dev_new_post (parser.steal_root ());
	}

	private void ws_cr_bind (GLib.Object item) {
		((Gtk.ListItem) item).child = new Gtk.Label (((WindowSize)((Gtk.ListItem) item).item).name);
	}

	private void update_home_badge (double value) {
		Tuba.Mastodon.Account.PLACE_HOME.badge = (int) value;
	}

	private void update_notification_badge (double value) {
		accounts.active.unread_count = (int) value;
	}

	private void update_unread_announcements (double value) {
		accounts.active.unread_announcements = (int) value;
	}

	private void update_unreviewd_fr (double value) {
		accounts.active.unreviewed_follow_requests = (int) value;
	}

	private void update_window_size (WindowSize windowsize) {
		app.main_window.set_default_size (windowsize.w, windowsize.h);
	}

	private void update_color_scheme (bool dark_mode) {
		Adw.StyleManager.get_default ().color_scheme = dark_mode ? Adw.ColorScheme.FORCE_DARK : Adw.ColorScheme.FORCE_LIGHT;
	}
}
