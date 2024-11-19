[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/schedule.ui")]
public class Tuba.Dialogs.Schedule : Adw.Dialog {
	public signal void schedule_picked (string iso8601);

	[GtkChild] unowned Gtk.Calendar calendar;
	[GtkChild] unowned Adw.SpinRow hours_spin_row;
	[GtkChild] unowned Adw.SpinRow minutes_spin_row;
	[GtkChild] unowned Adw.SpinRow seconds_spin_row;
	[GtkChild] unowned Adw.ComboRow timezone_combo_row;
	[GtkChild] unowned Gtk.Button schedule_button;

	GLib.DateTime result_dt;
	construct {
		calendar.remove_css_class ("view");

		string local = (new TimeZone.local ()).get_identifier ();
		string[] timezones = { local };
		if (local != "UTC") timezones += "UTC";
		timezone_combo_row.model = new Gtk.StringList (timezones);

		GLib.DateTime now = new GLib.DateTime.now_local ();
		hours_spin_row.value = (double) now.get_hour ();
		minutes_spin_row.value = (double) now.get_minute ();
		seconds_spin_row.value = (double) now.get_second ();

		validate ();
	}

	[GtkCallback] void on_exit () {
		this.force_close ();
	}

	[GtkCallback] void on_schedule () {
		schedule_picked (result_dt.format_iso8601 ());
		on_exit ();
	}

	[GtkCallback] void validate () {
		bool valid = true;
		GLib.DateTime now = new GLib.DateTime.now_utc ();

		if (((Gtk.StringObject) timezone_combo_row.selected_item).string == "UTC") {
			result_dt = new GLib.DateTime.utc (
				calendar.year,
				calendar.month + 1,
				calendar.day,
				(int) hours_spin_row.value,
				(int) minutes_spin_row.value,
				seconds_spin_row.value
			);
		} else {
			result_dt = new GLib.DateTime.local (
				calendar.year,
				calendar.month + 1,
				calendar.day,
				(int) hours_spin_row.value,
				(int) minutes_spin_row.value,
				seconds_spin_row.value
			).to_utc ();
		}

		var delta = result_dt.difference (now);
		if (delta < TimeSpan.HOUR) valid = delta / TimeSpan.MINUTE > 5;

		schedule_button.sensitive = valid;
	}
}
