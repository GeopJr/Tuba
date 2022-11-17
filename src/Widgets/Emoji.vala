using Gtk;
using Gdk;

public class Tooth.Widgets.Emoji : Adw.Bin {

	protected Image image;

	construct {
		image = new Gtk.Image ();
        child = image;
	}


    public Emoji (string emoji_url) {
		image_cache.request_paintable (emoji_url, on_cache_response);
	}

	void on_cache_response (bool is_loaded, owned Paintable? data) {
		(child as Image).paintable = data;
	}
}
