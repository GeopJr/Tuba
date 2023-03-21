using Gtk;
using Gdk;

public class Tooth.Widgets.Attachment.Image : Widgets.Attachment.Item {
	const string[] ALLOWED_TYPES = {"IMAGE", "VIDEO", "GIFV", "AUDIO"};
	const string[] VIDEO_TYPES = {"GIFV", "VIDEO", "AUDIO"};

	protected Gtk.Picture pic;
	protected Overlay media_overlay;

	construct {
		pic = new Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true,
			css_classes = {"attachment-picture"}
			//  content_fit = ContentFit.COVER // vala is not aware of it
		};

		#if GTK_4_8
			pic.set_property ("content-fit", 2);
		#endif

		media_overlay = new Overlay ();
		media_overlay.child = pic;

		button.child = media_overlay;
	}

	protected override void on_rebind () {
		base.on_rebind ();
		pic.alternative_text = entity == null ? null : entity.description;
		image_cache.request_paintable (entity.preview_url, on_cache_response);
		
		if (media_kind in VIDEO_TYPES) {
			var icon = new Gtk.Image() {
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};

			if (media_kind != "AUDIO") {
				icon.add_css_class("osd");
				icon.add_css_class("circular");
				icon.add_css_class("attachment-overlay-icon");
				icon.icon_name = "media-playback-start-symbolic";
			} else {
				icon.icon_name = "tooth-music-note-symbolic";
			}

			media_overlay.add_overlay (icon);

			// Doesn't get applied sometimes when set above
			icon.icon_size = Gtk.IconSize.LARGE;
		}
	}

	protected virtual void on_cache_response (bool is_loaded, owned Paintable? data) {
		pic.paintable = data;
	}

	protected override void on_click () {
		if (media_kind in ALLOWED_TYPES) {
			app.main_window.show_media_viewer(entity.url, pic.alternative_text, media_kind in VIDEO_TYPES);
		} else { // Fallback
			base.on_click();
		}
	}
}
