public class Tuba.Units {
    public struct ShortUnit {
        int64 top;
        string symbol;
    }

    public const ShortUnit[] short_units = {
        { 1000, "" },
        // translators: short unit suffix for thousands
        //              3000 => 3k
        { 1000000, "k" },
        // translators: short unit suffix for millions
        //              3000000 => 3M
        { 1000000000, "M" },
        // translators: short unit suffix for billions
        //              3000000000 => 3G
        { 1000000000000, "G" }
    };

    public static string shorten (int64 unit) {
        if (unit < 1000) return unit.to_string ();

        for (var i = 1; i < short_units.length; i++) {
            var short_unit = short_units[i];
            if (unit >= short_unit.top) continue;

            var shortened_unit = "%.1f".printf (Math.trunc(((double) unit / short_units[i-1].top)*10.0)/10.0);
            if (shortened_unit.has_suffix ("0") || shortened_unit.length > 3) {
                shortened_unit = shortened_unit.slice (0, shortened_unit.length - 2);
            }

            return @"$shortened_unit$(short_unit.symbol)";
        }

        return "♾️";
    }
}
