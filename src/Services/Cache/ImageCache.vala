using Gdk;

public class Tooth.ImageCache : AbstractCache {

	public delegate void OnItemChangedFn (bool is_loaded, owned Paintable? data);

	protected Paintable decode (owned Soup.Message msg) throws Error {
		var code = msg.status_code;
		if (code != Soup.Status.OK) {
			var error = msg.reason_phrase;
			throw new Oopsie.INSTANCE (@"Server returned $error");
		}

        var data = msg.response_body.flatten ().data;
        var stream = new MemoryInputStream.from_data (data);
        var pixbuf = new Pixbuf.from_stream (stream);
        stream.close ();

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
            ulong id = 0;
            id = download_msg.finished.connect (() => {
                Paintable? paintable = null;
                try {
                    paintable = decode (download_msg);
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

            network.queue (download_msg, (sess, mess) => {},
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
