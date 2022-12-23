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
		var image_widget = (child as Image);
		if (child != null && image_widget != null)
			image_widget.paintable = data;
	}
}
