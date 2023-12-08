public class Tuba.DateTime {

	public static string humanize_left (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();
		var delta = date.difference (now);
		if (delta < 0) {
			return humanize (iso8601);
		} else if (delta <= TimeSpan.MINUTE) {
			return _("expires soon");
		} else if (delta < TimeSpan.HOUR) {
			var minutes = delta / TimeSpan.MINUTE;
			// tranlators: the variable is a number, `m` as in minutes in short form
			return _("%sm left").printf (minutes.to_string ());
		} else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			// tranlators: the variable is a number, `h` as in hours in short form
			return _("%sh left").printf (hours.to_string ());
		} else if (delta <= (TimeSpan.DAY * 60)) {
			var days = delta / TimeSpan.DAY;
			// tranlators: the variable is a number, `d` as in days in short form
			return _("%sd left").printf (days.to_string ());
		} else {
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			//				 %Y is the year (with century)
			return date.to_timezone (new TimeZone.local ()).format (_("expires on %b %-e, %Y"));
		}
	}

	public static string humanize_ago (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();
		var delta = now.difference (date);
		if (delta < 0)
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			//				 %Y is the year (with century)
			//				 %H is the hours (24h format)
			//				 %m is the minutes
			return date.to_timezone (new TimeZone.local ()).format (_("expires on %b %-e, %Y %H:%m"));
		else if (delta <= TimeSpan.MINUTE)
			return _("expired on just now");
		else if (delta < TimeSpan.HOUR) {
			var minutes = delta / TimeSpan.MINUTE;
			// tranlators: the variable is a number, `m` as in minutes in short form
			return _("expired %sm ago").printf (minutes.to_string ());
		}
		else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			// tranlators: the variable is a number, `h` as in hours in short form
			return _("expired %sh ago").printf (hours.to_string ());
		}
		else if (is_same_day (now, date.add_days (1))) {
			return _("expired yesterday");
		}
		else if (date.get_year () == now.get_year ()) {
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			return date.to_timezone (new TimeZone.local ()).format (_("expired on %b %-e"));
		}
		else {
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			//				 %Y is the year (with century)
			return date.to_timezone (new TimeZone.local ()).format (_("expired on %b %-e, %Y"));
		}
	}

	public static string humanize (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();
		var delta = now.difference (date);
		if (delta < 0)
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			//				 %Y is the year (with century)
			//				 %H is the hours (24h format)
			//				 %m is the minutes
			return date.to_timezone (new TimeZone.local ()).format (_("%b %-e, %Y %H:%m"));
		else if (delta <= TimeSpan.MINUTE)
			return _("Just now");
		else if (delta < TimeSpan.HOUR) {
			var minutes = delta / TimeSpan.MINUTE;
			// tranlators: the variable is a number, `m` as in minutes in short form
			return _("%sm").printf (minutes.to_string ());
		}
		else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			// tranlators: the variable is a number, `h` as in hours in short form
			return _("%sh").printf (hours.to_string ());
		}
		else if (is_same_day (now, date.add_days (1))) {
			return _("Yesterday");
		}
		else if (date.get_year () == now.get_year ()) {
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			return date.to_timezone (new TimeZone.local ()).format (_("%b %-e"));
		}
		else {
			//  translators: %b is Month name (short)
			//				 %-e is the Day number
			//				 %Y is the year (with century)
			return date.to_timezone (new TimeZone.local ()).format (_("%b %-e, %Y"));
		}
	}

	public static string humanize_old (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();
		var delta = now.difference (date);
		if (delta < 0) {
			// non-translated: the date should always be in the past
			return "in the future";
		} else if (delta <= TimeSpan.MINUTE)
			// tranlators: less than 1 minute old
			return _("less than a minute old");
		else if (delta < TimeSpan.HOUR) {
			var minutes = delta / TimeSpan.MINUTE;
			// tranlators: the variable is a number
			return _("%s minutes old").printf (minutes.to_string ());
		} else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			// tranlators: the variable is a number
			return GLib.ngettext ("an hour old", "%s hours old", (ulong) hours).printf (hours.to_string ());
		}

		var date_day_oty = date.get_day_of_year ();
		var now_day_oty = now.get_day_of_year ();

		var date_month = date.get_month ();
		var now_month = now.get_month ();

		var date_year = date.get_year ();
		var now_year = now.get_year ();

		if (date_year == now_year) {
			if (now_month > date_month) {
				// tranlators: the variable is a number
				return _("%d months old").printf (now_month - date_month);
			}

			var day_diff = now_day_oty - date_day_oty;
			if (now_day_oty == date_day_oty || day_diff == 1) {
				// tranlators: 1 day old
				return _("a day old");
			} else {
				// tranlators: the variable is a number
				return _("%d days old").printf (day_diff);
			}
		} else {
			var year_diff = now_year - date_year;
			if (year_diff > 1) {
				// tranlators: the variable is a number
				return _("%d years old").printf (year_diff);
			} else if (year_diff == 1) {
				return _("a year old");
			} else {
				// tranlators: the variable is a number
				return _("%d months old").printf (now_month + 12 - date_month);
			}
		}
	}

	public static bool is_3_months_old (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();
		if (now.difference (date) < 0) return false;

		var date_month = date.get_month ();
		var now_month = now.get_month ();

		if (date.get_year () == now.get_year ()) {
			return now_month - date_month > 3;
		} else {
			return now_month + 12 - date_month > 3;
		}
	}

	public static bool is_same_day (GLib.DateTime d1, GLib.DateTime d2) {
		return (d1.get_day_of_year () == d2.get_day_of_year ()) && (d1.get_year () == d2.get_year ());
	}
}
