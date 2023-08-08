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
        if (unit < 1000) return unit.to_string ();

        for (var i = 1; i < SHORT_UNITS.length; i++) {
            var short_unit = SHORT_UNITS[i];
            if (unit >= short_unit.top) continue;

            var shortened_unit = "%.1f".printf (Math.trunc (((double) unit / SHORT_UNITS[i - 1].top) * 10.0) / 10.0);
            if (shortened_unit.has_suffix ("0") || shortened_unit.length > 3) {
                shortened_unit = shortened_unit.slice (0, shortened_unit.length - 2);
            }

            return @"$shortened_unit$(short_unit.symbol)";
        }

        return "♾️";
    }
}
