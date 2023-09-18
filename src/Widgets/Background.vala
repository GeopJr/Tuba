public class Tuba.Widgets.Background : Gtk.Button {
	private Gtk.Picture background;
	public Gdk.Paintable? paintable {
		get { return background.paintable; }
		set { background.paintable = value; }
	}

	construct {
		background = new Gtk.Picture () {
			content_fit = Gtk.ContentFit.COVER,
			css_classes = { "header-image" }
		};
		child = background;
		css_classes = { "flat", "image-button", "ttl-flat-button" };
	}
}
