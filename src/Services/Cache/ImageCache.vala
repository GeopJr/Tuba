public class Tuba.ImageCache : AbstractCache {

	public delegate void OnItemChangedFn (bool is_loaded, owned Gdk.Paintable? data);

	protected static async Gdk.Paintable decode (owned Soup.Message msg, owned InputStream in_stream) throws Error {
		var code = msg.status_code;
		if (code != Soup.Status.OK) {
			var error = msg.reason_phrase;
			throw new Oopsie.INSTANCE (@"Server returned $error");
		}

		return Gdk.Texture.for_pixbuf ((yield new Gdk.Pixbuf.from_stream_async (in_stream)).apply_embedded_orientation ());
	}

	public static void request_paintable (string? url, owned OnItemChangedFn cb) {
		if (url == null) return;
		new Tuba.AbstractCache ();

		var key = get_key (url);
		//  Soup.Message download_msg = (Soup.Message) items_in_progress.@get (key);
		//  if (download_msg == null) {
			cb (false, null);

			var download_msg = new Soup.Message ("GET", url);
			network.queue (download_msg, null, (sess, mess, t_in_stream) => {
				decode.begin (download_msg, t_in_stream, (obj, async_res) => {
					Gdk.Paintable? paintable = null;
					try {
						paintable = decode.end (async_res);
					} catch (Error e) {
						warning (@"Failed to download image at \"$url\". $(e.message).");
						cb (true, null);

						return;
					}

					Signal.emit_by_name (download_msg, "finished");
					//  items_in_progress.unset (key);

					cb (true, paintable);
				});
			},
			(code, reason) => {
				cb (true, null);
			});

		//  	items_in_progress.@set (key, download_msg);
		//  } else {
		//  	// This image is either cached or already downloading, so we can serve the result immediately.

		//  	ulong id = 0;
		//  	id = download_msg.finished.connect (() => {
		//  		cb (true, lookup (key) as Gdk.Paintable);

		//  		download_msg.disconnect (id);
		//  	});
		//  }
	}

}
