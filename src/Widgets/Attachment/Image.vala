using Gtk;
using Gdk;

public class Tooth.Widgets.Attachment.Image : Widgets.Attachment.Item {

	protected Gtk.Picture pic;

	construct {
		pic = new Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true
		};
		button.child = pic;
	}

	protected override void on_rebind () {
		base.on_rebind ();
		image_cache.request_paintable (entity.preview_url, on_cache_response);
	}

	protected virtual void on_cache_response (bool is_loaded, owned Paintable? data) {
		pic.paintable = data;
	}

}
