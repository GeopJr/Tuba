public class Tuba.Units {
    public enum ShortUnitType {
		NONE,
		THOUSAND,
		MILLION,
		BILLION;

		public string to_string () {
			switch (this) {
				case THOUSAND:
                    // translators: short unit suffix for thousands
                    //              3000 => 3k
					return _("k");
				case MILLION:
                    // translators: short unit suffix for millions
                    //              3000000 => 3M
					return _("M");
                case BILLION:
                    // translators: short unit suffix for billions
                    //              3000000000 => 3G
                    return _("G");
				default:
					return "";
			}
		}
	}

    public struct ShortUnit {
        int64 top;
        ShortUnitType symbol;
    }

    public const ShortUnit[] SHORT_UNITS = {
        { 1000, ShortUnitType.NONE },
        { 1000000, ShortUnitType.THOUSAND },
        { 1000000000, ShortUnitType.MILLION },
        { 1000000000000, ShortUnitType.BILLION }
    };

    public static string shorten (int64 unit) {
        if (
            unit == 0
            || (unit < 0 && unit > -1000)
            || (unit > 0 && unit < 1000)
        ) return unit.to_string ();

        // If unit is negative, make it positive
        // and later add the `-` prefix
        bool is_negative = unit < 0;
        if (is_negative) unit = unit * -1;

        for (var i = 1; i < SHORT_UNITS.length; i++) {
            var short_unit = SHORT_UNITS[i];
            if (unit >= short_unit.top) continue;

            // We want the string to always have one decimal point
            // We first devide by the previous top value | 1312 / 1000 => 1.312
            // then multiply by 10 | 13.12
            // trunc it | 13
            // and then devide by 10 | 1.3
            var shortened_unit = "%.1f".printf (
                Math.trunc (((double) unit / SHORT_UNITS[i - 1].top) * 10.0) / 10.0
            );

            // If it ends in .0 (13.0) or has more than 3 characters (999.9)
            // remove the last two (13, 999)
            if (shortened_unit.has_suffix ("0") || shortened_unit.length > 3) {
                shortened_unit = shortened_unit.slice (0, shortened_unit.length - 2);
            }

            return @"$(is_negative ? "-" : "")$shortened_unit$(short_unit.symbol)";
        }

        return "♾️";
    }
}
