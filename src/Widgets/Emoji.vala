using Gtk;
using Gdk;

public class Tuba.Widgets.Emoji : Adw.Bin {

	protected Image image;
	public string? shortcode { get; set; } 

	construct {
		image = new Gtk.Image ();
        child = image;
	}

    public Emoji (string emoji_url, string? t_shortcode = null) {
		if (t_shortcode != null) {
			image.tooltip_text = t_shortcode;
			shortcode = t_shortcode;
		}

		image_cache.request_paintable (emoji_url, on_cache_response);
	}

	void on_cache_response (bool is_loaded, owned Paintable? data) {
		var image_widget = (child as Image);
		if (child != null && image_widget != null)
			image_widget.paintable = data;
	}
}
