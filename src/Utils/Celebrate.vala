// Celebrate is inspired by Warp's pride.rs
// https://gitlab.gnome.org/World/warp/-/blob/main/src/ui/pride.rs

public class Tuba.Celebrate {
    enum CelebrateStyle {
		INTERSEX,
		LESBIAN,
		AIDS,
		PAN,
        TRANS,
        BI,
        AGENDER,
        DISABILITY,
        BLACK_HISTORY,
        ARO,
        ACE,
        NON_BINARY,
        AUTISM;

		public string to_string () {
			switch (this) {
				case INTERSEX:
					return "intersex";
				case LESBIAN:
					return "lesbian";
				case AIDS:
					return "aids";
                case PAN:
					return "pan";
                case TRANS:
					return "trans";
                case BI:
					return "bi";
                case AGENDER:
					return "agender";
                case DISABILITY:
					return "disability";
                case BLACK_HISTORY:
					return "black-history";
                case ARO:
					return "aro";
                case ACE:
					return "ace";
                case NON_BINARY:
					return "non-binary";
                case AUTISM:
					return "autism";
                default:
                    assert_not_reached ();
			}
		}
	}

    struct Celebration {
        int day;
        int month;
        CelebrateStyle css_class;
    }

    const Celebration[] CELEBRATIONS_DAYS = {
        // Intersex Awareness Day
        { 26, 10, CelebrateStyle.INTERSEX },
        // Intersex Day Of Remembrance
        { 8, 11, CelebrateStyle.INTERSEX },
        // International Lesbian Day
        { 8, 10, CelebrateStyle.LESBIAN },
        // World AIDS Day
        { 1, 12, CelebrateStyle.AIDS },
        // Autistic Pride Day
        { 18, 6, CelebrateStyle.AUTISM },
        // Pansexual and Panromantic Awareness and Visibility Day
        { 24, 5, CelebrateStyle.PAN },
        // TDOR
        { 20, 11, CelebrateStyle.TRANS },
        // TDOV
        { 31, 3, CelebrateStyle.TRANS },
        // Bi Visibility Day
        { 23, 9, CelebrateStyle.BI },
        // Agender Pride Day
        { 19, 5, CelebrateStyle.AGENDER },
    };

    const Celebration[] CELEBRATIONS_WEEKS = {
        // Lesbian Visibility Week
        { 26, 4, CelebrateStyle.LESBIAN },
        // Trans Awareness Week
        { 13, 11, CelebrateStyle.TRANS },
        // Bisexual Awareness Week
        { 16, 9, CelebrateStyle.BI },
    };

    const Celebration[] CELEBRATIONS_MONTHS = {
        // Disability Pride Month
        { 0, 7, CelebrateStyle.DISABILITY },
        // Black History Month
        { 0, 2, CelebrateStyle.BLACK_HISTORY },
        { 0, 10, CelebrateStyle.BLACK_HISTORY }
    };

    private static Celebration[] get_dynamic_weeks (GLib.DateTime date) {
        return {
            // Aromantic Spectrum Awareness Week
            get_arospec_week (date),
            // Ace Week
            get_ace_week (date),
            // Non-Binary Awareness Week
            get_enby_week (date),
        };
    }

    private static Celebration get_arospec_week (GLib.DateTime date) {
        // The week following 14th February (Sunday-Saturday)
        var february_14 = new GLib.DateTime.local (date.get_year (), 2, 14, 0, 0, 0);
        var weekday_offset = february_14.get_day_of_week () % 7;
        var start = 14 + 7 - weekday_offset;

        return { start, 2, CelebrateStyle.ARO };
    }

    private static Celebration get_ace_week (GLib.DateTime date) {
        // Last week of October, starting on Sunday
        var last_day_october = new GLib.DateTime.local (date.get_year (), 10, 31, 0, 0, 0);
        var weekday_offset_last_day_october = last_day_october.get_day_of_week () % 7;
        var start = weekday_offset_last_day_october == 6 ? 31 - 7 : 31 - weekday_offset_last_day_october - 7;

        return { start, 10, CelebrateStyle.ACE };
    }

    private static Celebration get_enby_week (GLib.DateTime date) {
        // The week, starting Sunday/Monday, surrounding 14 July
        // We will just start on Sunday and end on Monday, so 8 days
        var july_14 = new GLib.DateTime.local (date.get_year (), 7, 14, 0, 0, 0);
        var weekday_july_14_offset = july_14.get_day_of_week () - 1;
        var start = 14 - weekday_july_14_offset;

        return { start, 7, CelebrateStyle.NON_BINARY };
    }

    public static string get_celebration_css_class (GLib.DateTime date) {
        var celebration = get_celebration (date);
        return celebration == null ? "" : @"theme-$(celebration.css_class)";
    }

    private static Celebration? get_celebration (GLib.DateTime date) {
        var celebration = get_celebration_day (date);
        if (celebration == null) celebration = get_celebration_week (date);
        if (celebration == null) celebration = get_celebration_month (date);

        return celebration;
    }

    private static Celebration? get_celebration_day (GLib.DateTime date) {
        Celebration[] res = {};
        var month = date.get_month ();
        var day = date.get_day_of_month ();

        foreach (var celebration in CELEBRATIONS_DAYS) {
            if (celebration.month == month && celebration.day == day) res += celebration;
        }

        return get_random_item (res);
    }

    private static Celebration? get_celebration_week (GLib.DateTime date) {
        Celebration[] res = {};
        var year = date.get_year ();
        var day = date.get_day_of_year ();

        var weeks = get_dynamic_weeks (date);
        foreach (var celebration in CELEBRATIONS_WEEKS) {
            weeks += celebration;
        }

        foreach (var celebration in weeks) {
            var celebration_pre_week = new GLib.DateTime.local (year, celebration.month, celebration.day, 0, 0, 0);
            var week = celebration_pre_week.add_weeks (1);
            if (
                day >= celebration_pre_week.get_day_of_year ()
                && day <= week.get_day_of_year () - 1
            ) res += celebration;
        }

        return get_random_item (res);
    }

    private static Celebration? get_celebration_month (GLib.DateTime date) {
        Celebration[] res = {};
        var month = date.get_month ();

        foreach (var celebration in CELEBRATIONS_MONTHS) {
            if (celebration.month == month) res += celebration;
        }

        if (res.length == 0) return null;
        return get_random_item (res);
    }

    private static Celebration? get_random_item (Celebration[] res) {
        if (res.length == 0) return null;
        if (res.length == 1) return res[0];
        return res[Random.int_range (0, res.length)];
    }
}
