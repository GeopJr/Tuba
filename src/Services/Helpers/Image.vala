public class Tuba.Helper.Image {
	public delegate void OnItemChangedFn (owned Gdk.Paintable? data);

	protected static async Gdk.Paintable decode (owned Soup.Message msg, owned InputStream in_stream) throws Error {
		if (msg.status_code != Soup.Status.OK) {
			throw new Oopsie.INSTANCE (@"Server returned $(msg.reason_phrase)");
		}

		return Gdk.Texture.for_pixbuf ((yield new Gdk.Pixbuf.from_stream_async (in_stream)).apply_embedded_orientation ());
	}

	public static void request_paintable (string? url, string? blurhash, owned OnItemChangedFn cb) {
		if (url == null) return;
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
		network.queue (download_msg, null, (sess, mess, t_in_stream) => {
			decode.begin (download_msg, t_in_stream, (obj, async_res) => {
				has_loaded = true;
				Gdk.Paintable? paintable = null;
				try {
					paintable = decode.end (async_res);
				} catch (Error e) {
					warning (@"Failed to download image at \"$url\". $(e.message).");
					cb (null);

					return;
				}

				cb (paintable);
			});
		},
		(code, reason) => {
			has_loaded = true;
			cb (null);
		});
	}
}
