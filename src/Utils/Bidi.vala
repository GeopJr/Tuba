// https://discourse.gnome.org/t/how-to-bidi-isolate-in-pango/39486/2
public class Tuba.Utils.Bidi {
	public static string isolate (string str) {
		// TODO: replace bidi isolate unicode from str?
		return @"⁨$str⁩";
	}
}
