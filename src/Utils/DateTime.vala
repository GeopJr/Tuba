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
			return _(@"$(minutes)m left");
		} else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			return _(@"$(hours)h left");
		} else if (delta <= (TimeSpan.DAY * 60)) {
			var days = delta / TimeSpan.DAY;
			return _(@"$(days)d left");
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
			return _(@"expired $(minutes)m ago");
		}
		else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			return _(@"expired $(hours)h ago");
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
		if (delta <= TimeSpan.MINUTE)
			return _("less than a minute old");
		else if (delta < TimeSpan.HOUR) {
			var minutes = delta / TimeSpan.MINUTE;
			return _(@"$(minutes) minutes old");
		} else if (delta <= TimeSpan.DAY) {
			var hours = delta / TimeSpan.HOUR;
			return _(@"$(hours) hours old");
		}

		var date_day_oty = date.get_day_of_year ();
		var now_day_oty = now.get_day_of_year ();

		var date_month = date.get_month ();
		var now_month = now.get_month ();

		var date_year = date.get_year ();
		var now_year = now.get_year ();

		if (date_year == now_year) {
			if (now_month > date_month) {
				return _(@"$(now_month - date_month) months old");
			} else if (now_day_oty == date_day_oty) {
				return _("a day old");
			} else {
				return _(@"$(now_day_oty - date_day_oty) days old");
			}
		} else {
			var year_diff = now_year - date_year;
			if (year_diff > 1) {
				return _(@"$(year_diff) years old");
			} else if (year_diff == 1) {
				return _("a year old");
			} else {
				return _(@"$(now_month + 12 - date_month) months old");
			}
		}
	}

	public static bool is_3_months_old (string iso8601) {
		var date = new GLib.DateTime.from_iso8601 (iso8601, null);
		var now = new GLib.DateTime.now_local ();

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
