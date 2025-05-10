public class Tuba.Widgets.Background : Gtk.Button {
	private Gtk.Picture background;
	public Gdk.Paintable? paintable {
		get { return background.paintable; }
		set { background.paintable = value; }
	}

	public string? alternative_text {
		get { return background.alternative_text; }
		set { background.alternative_text = value; }
	}

	construct {
		background = new Gtk.Picture () {
			content_fit = Gtk.ContentFit.COVER,
		};
		child = background;
		css_classes = { "flat", "image-button", "ttl-flat-button", "header-image" };
	}
}
