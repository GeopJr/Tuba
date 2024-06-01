public class Tuba.Helper.Video {
	private static Soup.Session session;
	private static Soup.Cache cache;

	public static void clear_cache () {
		new Helper.Video ();
		cache.clear ();
	}

	public static void flush_cache () {
		new Helper.Video ();
		cache.flush ();
		cache.dump ();
	}

	static construct {
		cache = new Soup.Cache (
			GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S, Tuba.cache_path, "soup", "videos"),
			Soup.CacheType.SINGLE_USER
		);
		cache.load ();
		cache.set_max_size (1024 * 1024 * 100 * 2);

		session = new Soup.Session.with_options ("max-conns", 64, "max-conns-per-host", 64) {
			user_agent = @"$(Build.NAME)/$(Build.VERSION) libsoup/$(Soup.get_major_version()).$(Soup.get_minor_version()).$(Soup.get_micro_version()) ($(Soup.MAJOR_VERSION).$(Soup.MINOR_VERSION).$(Soup.MICRO_VERSION))" // vala-lint=line-length
		};
		session.add_feature (cache);
	}

	public static async InputStream request (string? url) throws Oopsie {
		if (url == null || url == "") throw new Tuba.Oopsie.INTERNAL ("No url provided");
		new Helper.Video ();

		var download_msg = new Soup.Message ("GET", url);
        try {
			return yield session.send_async (download_msg, 0, null);
		} catch (Error e) {
		    throw new Tuba.Oopsie.INTERNAL (@"Failed to get video at \"$url\": $(e.message)");
		}
	}
}
