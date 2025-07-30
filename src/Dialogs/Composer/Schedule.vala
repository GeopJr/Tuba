[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/schedule.ui")]
public class Tuba.Dialogs.Schedule : Adw.NavigationPage {
	public signal void schedule_picked (string iso8601);

	[GtkChild] unowned Gtk.Calendar calendar;
	[GtkChild] unowned Gtk.SpinButton hours_spin_button;
	[GtkChild] unowned Gtk.SpinButton minutes_spin_button;
	[GtkChild] unowned Gtk.SpinButton seconds_spin_button;
	[GtkChild] unowned Adw.ComboRow timezone_combo_row;
	[GtkChild] unowned Gtk.Button schedule_button;

	GLib.DateTime result_dt;
	construct {
		calendar.remove_css_class ("view");

		string local = (new TimeZone.local ()).get_identifier ();
		string[] timezones = { local };
		if (local != "UTC") timezones += "UTC";
		timezone_combo_row.model = new Gtk.StringList (timezones);
	}

	public Schedule (string? iso8601 = null, string? button_label = null) {
		if (iso8601 == null) {
			GLib.DateTime now = new GLib.DateTime.now_local ();
			hours_spin_button.value = (double) now.get_hour ();
			minutes_spin_button.value = (double) now.get_minute ();
			seconds_spin_button.value = (double) now.get_second ();
		} else {
			GLib.DateTime iso8601_datetime = new GLib.DateTime.from_iso8601 (iso8601, null).to_timezone (new TimeZone.local ());
			hours_spin_button.value = (double) iso8601_datetime.get_hour ();
			minutes_spin_button.value = (double) iso8601_datetime.get_minute ();
			seconds_spin_button.value = (double) iso8601_datetime.get_second ();

			calendar.year = iso8601_datetime.get_year ();
			calendar.month = iso8601_datetime.get_month () - 1;
			calendar.day = iso8601_datetime.get_day_of_month ();
		}

		if (button_label != null) schedule_button.label = button_label;

		calendar.day_selected.connect (validate);
		hours_spin_button.value_changed.connect (validate);
		minutes_spin_button.value_changed.connect (validate);
		seconds_spin_button.value_changed.connect (validate);
		timezone_combo_row.notify["selected"].connect (validate);
		validate ();
	}

	[GtkCallback] void on_schedule () {
		schedule_picked (result_dt.format_iso8601 ());
	}

	void validate () {
		bool valid = true;
		GLib.DateTime now = new GLib.DateTime.now_utc ();
		if (timezone_combo_row.selected != Gtk.INVALID_LIST_POSITION && ((Gtk.StringObject) timezone_combo_row.selected_item).string == "UTC") {
			result_dt = new GLib.DateTime.utc (
				calendar.year,
				calendar.month + 1,
				calendar.day,
				(int) hours_spin_button.value,
				(int) minutes_spin_button.value,
				seconds_spin_button.value
			);
		} else {
			result_dt = new GLib.DateTime.local (
				calendar.year,
				calendar.month + 1,
				calendar.day,
				(int) hours_spin_button.value,
				(int) minutes_spin_button.value,
				seconds_spin_button.value
			).to_utc ();
		}

		var delta = result_dt.difference (now);
		if (delta < TimeSpan.HOUR) valid = delta / TimeSpan.MINUTE > 5;

		schedule_button.sensitive = valid;
	}

	public override void measure (
		Gtk.Orientation orientation,
		int for_size,
		out int minimum,
		out int natural,
		out int minimum_baseline,
		out int natural_baseline
	) {
		base.measure (
			orientation,
			for_size,
			out minimum,
			out natural,
			out minimum_baseline,
			out natural_baseline
		);

		if (orientation == HORIZONTAL) natural = int.max (minimum, int.max (natural, 423));
	}
}
