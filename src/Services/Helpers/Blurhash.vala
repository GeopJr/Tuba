public class Tuba.Helper.Blurhash {
	public static Gdk.Paintable? decode (string? blurhash) {
		if (blurhash == null) return null;

		var pixbuf = Tuba.Blurhash.blurhash_to_pixbuf (blurhash, 32, 32);
		if (pixbuf != null) {
			var paintable = Gdk.Texture.for_pixbuf (pixbuf);

			return paintable;
		}

		return null;
	}
}
