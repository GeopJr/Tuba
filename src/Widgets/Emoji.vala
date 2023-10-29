public class Tuba.Widgets.Emoji : Adw.Bin {

	protected Gtk.Image image;
	public string? shortcode { get; set; }
	public int pixel_size {
		get { return image.pixel_size; }
		set { image.pixel_size = value; }
	}
	public Gtk.IconSize icon_size {
		get { return image.icon_size; }
		set { image.icon_size = value; }
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
			Tuba.Helper.Image.request_paintable (emoji_url, null, on_cache_response);
			return GLib.Source.REMOVE;
		});
	}

	void on_cache_response (Gdk.Paintable? data) {
		image.paintable = data;
	}
}
