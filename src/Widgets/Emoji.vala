using Gtk;
using Gdk;

public class Tuba.Widgets.Emoji : Adw.Bin {

	protected Image image;
	public string? shortcode { get; set; }
	public int pixel_size {
		get { return image.pixel_size; }
		set { image.pixel_size = value; }
	}

	construct {
		image = new Gtk.Image () {
			css_classes = { "lww-emoji" }
		};
        child = image;
	}

    public Emoji (string emoji_url, string? t_shortcode = null) {
		if (t_shortcode != null) {
			image.tooltip_text = t_shortcode;
			shortcode = t_shortcode;
		}

		GLib.Idle.add (() => {
			image_cache.request_paintable (emoji_url, on_cache_response);
			return GLib.Source.REMOVE;
		});
	}

	void on_cache_response (bool is_loaded, owned Paintable? data) {
		if (image != null)
			image.paintable = data;
	}
}
