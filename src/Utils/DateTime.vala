using GLib;

public class Tooth.DateTime {

	public static string humanize (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();
		var delta = now.difference (date);

		if (delta <= TimeSpan.MINUTE)
			return _("Just now");
		else if (delta < TimeSpan.HOUR) {
			var minutes = delta / TimeSpan.MINUTE;
			return _(@"$(minutes)m");
		}
		else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			return _(@"$(hours)h");
		}
		else if (is_same_day (now, date.add_days (1))) {
			return _("Yesterday");
		}
		else if (date.get_year () == now.get_year ()) {
			return date.format (_("%b %e"));
		}
		else {
			return date.format (_("%b %e, %Y"));
		}
	}

	public static bool is_same_day (GLib.DateTime d1, GLib.DateTime d2) {
		return (d1.get_day_of_year () == d2.get_day_of_year ()) && (d1.get_year () == d2.get_year ());
	}

}
