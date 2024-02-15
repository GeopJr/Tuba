public class Tuba.Helper.Image {
	public delegate void OnItemChangedFn (Gdk.Paintable? data);

	protected static async Gdk.Paintable decode (Soup.Message msg, InputStream in_stream) throws Error {
		if (msg.status_code != Soup.Status.OK) {
			throw new Oopsie.INSTANCE (@"Server returned $(msg.reason_phrase)");
		}

		return Gdk.Texture.for_pixbuf ((yield new Gdk.Pixbuf.from_stream_async (in_stream)).apply_embedded_orientation ());
	}

	private static Soup.Session session;
	private static Soup.Cache cache;

	public static void clear_cache () {
		new Helper.Image ();
		cache.clear ();
	}

	public static void flush_cache () {
		new Helper.Image ();
		cache.flush ();
		cache.dump ();
	}

	static construct {
		cache = new Soup.Cache (
			GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S, Tuba.cache_path, "soup", "media"),
			Soup.CacheType.SINGLE_USER
		);
		cache.load ();
		cache.set_max_size (1024 * 1024 * 100);

		session = new Soup.Session () {
			user_agent = @"$(Build.NAME)/$(Build.VERSION) libsoup/$(Soup.get_major_version()).$(Soup.get_minor_version()).$(Soup.get_micro_version()) ($(Soup.MAJOR_VERSION).$(Soup.MINOR_VERSION).$(Soup.MICRO_VERSION))" // vala-lint=line-length
		};
		session.add_feature (cache);
	}

	public static async Bytes? request_bytes (string url) {
		new Helper.Image ();

		var download_msg = new Soup.Message ("GET", url);
		try {
			return yield session.send_and_read_async (download_msg, 0, null);
		} catch (Error e) {
			warning (@"Failed to download and read image at \"$url\": $(e.message)");
			return null;
		}
	}

	public static void request_paintable (string? url, string? blurhash, owned OnItemChangedFn cb) {
		if (url == null || url == "") return;
		new Helper.Image ();
		bool has_loaded = false;
		cb (null);

		if (blurhash != null) {
			GLib.Idle.add (() => {
				if (!has_loaded)
					cb (Tuba.Helper.Blurhash.decode (blurhash));

				return GLib.Source.REMOVE;
			});
		}

		var download_msg = new Soup.Message ("GET", url);
		session.send_async.begin (download_msg, 0, null, (obj, res) => {
			try {
				var in_stream = session.send_async.end (res);

				decode.begin (download_msg, in_stream, (obj, async_res) => {
					has_loaded = true;
					Gdk.Paintable? paintable = null;
					try {
						paintable = decode.end (async_res);
					} catch (Error e) {
						warning (@"Failed to download image at \"$url\": $(e.message)");
						cb (null);

						return;
					}

					cb (paintable);
				});
			} catch (GLib.Error e) {
				warning (e.message);
				has_loaded = true;
				cb (null);
			}
		});
	}
}
