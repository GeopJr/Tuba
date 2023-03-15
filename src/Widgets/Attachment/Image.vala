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
		pic.alternative_text = entity == null ? null : entity.description;
		image_cache.request_paintable (entity.preview_url, on_cache_response);
	}

	protected virtual void on_cache_response (bool is_loaded, owned Paintable? data) {
		pic.paintable = data;
	}

	const string[] ALLOWED_TYPES = {"IMAGE", "VIDEO", "GIFV", "AUDIO"};
	const string[] VIDEO_TYPES = {"GIFV", "VIDEO", "AUDIO"};

	protected override void on_click () {
		if (badge.label in ALLOWED_TYPES) {
			app.main_window.show_media_viewer(entity.url, pic.alternative_text, badge.label in VIDEO_TYPES);
		} else { // Fallback
			base.on_click();
		}
	}
}
