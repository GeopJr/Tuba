public class Tuba.BlurhashCache : AbstractCache {
    public Gdk.Paintable? lookup_or_decode (string? blurhash) {
        if (blurhash == null) return null;

        var key = get_key (blurhash);
        if (contains (key)) return lookup (key) as Gdk.Paintable?;

        var pixbuf = Tuba.Blurhash.blurhash_to_pixbuf (blurhash, 32, 32);
		if (pixbuf != null) {
			var paintable = Gdk.Texture.for_pixbuf (pixbuf);
            insert (blurhash, paintable);

            return paintable;
		}

        return null;
    }
}
