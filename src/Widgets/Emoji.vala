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
		this.set_accessible_role (Gtk.AccessibleRole.IMG);
		image = new Gtk.Image () {
			css_classes = { "lww-emoji" }
		};
		child = image;
	}

	public Emoji (string emoji_url, string? t_shortcode = null) {
		if (t_shortcode != null) {
			this.tooltip_text = t_shortcode;
			shortcode = t_shortcode;
		}

		var cached_paintable = Tuba.Helper.Image.lookup_cache (emoji_url);
		if (cached_paintable == null)
			Tuba.Helper.Image.request_paintable (emoji_url, null, on_cache_response);
		else
			on_cache_response (cached_paintable);
	}

	void on_cache_response (Gdk.Paintable? data) {
		image.paintable = data;
	}
}
