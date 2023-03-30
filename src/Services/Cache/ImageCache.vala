using Gdk;

public class Tuba.ImageCache : AbstractCache {

	public delegate void OnItemChangedFn (bool is_loaded, owned Paintable? data);

	protected Paintable decode (owned Soup.Message msg, owned InputStream in_stream) throws Error {
		var code = msg.status_code;
		if (code != Soup.Status.OK) {
			var error = msg.reason_phrase;
			throw new Oopsie.INSTANCE (@"Server returned $error");
		}

        var pixbuf = new Pixbuf.from_stream (in_stream);

        return Gdk.Texture.for_pixbuf (pixbuf);
	}

	public void request_paintable (string? url, owned OnItemChangedFn cb) {
		if (url == null)
			return;

		var key = get_key (url);
		if (contains (key)) {
			cb (true, lookup (key) as Paintable);
			return;
		}

		var download_msg = items_in_progress.@get (key);
		if (download_msg == null) {
			// This image isn't cached, so we need to download it first.

            download_msg = new Soup.Message ("GET", url);
            InputStream? in_stream = null;
            ulong id = 0;
            id = download_msg.finished.connect (() => {
                Paintable? paintable = null;
                try {
                    if (in_stream == null) {
                        cb (true, null);
                        return;
                    }
                    paintable = decode (download_msg, in_stream);
                }
                catch (Error e) {
                    warning (@"Failed to download image at \"$url\". $(e.message).");
                    cb (true, null);
                    return;
                }

                // message (@"[*] $key");
                insert (url, paintable);
                items_in_progress.unset (key);

                cb (true, paintable);

                download_msg.disconnect (id);
            });

            network.queue (download_msg, null, (sess, mess, t_in_stream) => {
                in_stream = t_in_stream;
                Signal.emit_by_name (download_msg, "finished");
            },
            (code, reason) => {
                cb (true, null);
            });

            cb (false, null);

            items_in_progress.@set (key, download_msg);
		}
		else {
			// This image is either cached or already downloading, so we can serve the result immediately.

            //message ("[/]: %s", key);
            ulong id = 0;
            id = download_msg.finished.connect_after (() => {
                cb (true, lookup (key) as Paintable);
                download_msg.disconnect (id);
            });
        }
	}

}
