public class Tuba.BlurhashCache {
	public static Gdk.Paintable? lookup_or_decode (string? blurhash) {
		if (blurhash == null) return null;

		var pixbuf = Tuba.Blurhash.blurhash_to_pixbuf (blurhash, 32, 32);
		if (pixbuf != null) {
			var paintable = Gdk.Texture.for_pixbuf (pixbuf);

			return paintable;
		}

		return null;
	}
}
