using Gtk;
using Gdk;

public class Tuba.Widgets.Attachment.Image : Widgets.Attachment.Item {
	const string[] ALLOWED_TYPES = {"IMAGE", "VIDEO", "GIFV", "AUDIO"};
	const string[] VIDEO_TYPES = {"GIFV", "VIDEO", "AUDIO"};

	protected Gtk.Picture pic;
	protected Overlay media_overlay;

	private bool _spoiler = false;
	public bool spoiler {
		get {
			return _spoiler;
		}

		set {
			_spoiler = value;
			if (value) {
				pic.add_css_class ("spoilered-attachment");
			} else {
				pic.remove_css_class ("spoilered-attachment");
			}

			if (media_icon != null) media_icon.visible = !value;
		}
	}

	void cover_content_fit () {
		pic.set_property ("content-fit", settings.letterbox_media ? 1 : 2);
	}

	construct {
		pic = new Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true,
			css_classes = {"attachment-picture"}
			//  content_fit = ContentFit.COVER // GTK 4.8
		};

		#if GTK_4_8
			cover_content_fit ();
			settings.notify["letterbox-media"].connect (cover_content_fit);
		#endif

		media_overlay = new Overlay ();
		media_overlay.child = pic;

		button.child = media_overlay;
	}

	protected Gtk.Image? media_icon = null;
	protected override void on_rebind () {
		base.on_rebind ();
		pic.alternative_text = entity == null ? null : entity.description;
		image_cache.request_paintable (entity.preview_url, on_cache_response);

		if (media_kind in VIDEO_TYPES) {
			media_icon = new Gtk.Image () {
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};

			if (media_kind != "AUDIO") {
				media_icon.css_classes = { "osd", "circular", "attachment-overlay-icon" };
				media_icon.icon_name = "media-playback-start-symbolic";
			} else {
				media_icon.icon_name = "tuba-music-note-symbolic";
			}

			media_overlay.add_overlay (media_icon);

			// Doesn't get applied sometimes when set above
			media_icon.icon_size = Gtk.IconSize.LARGE;
		}
	}

	protected virtual void on_cache_response (bool is_loaded, owned Paintable? data) {
		pic.paintable = data;
	}

	public signal void spoiler_revealed ();
	protected override void on_click () {
		if (pic.has_css_class ("spoilered-attachment")) {
			spoiler_revealed ();
			return;
		}

		if (media_kind in ALLOWED_TYPES) {
			load_image_in_media_viewer (null);
			on_any_attachment_click (entity.url);
		} else { // Fallback
			base.on_click ();
		}
	}

	public void load_image_in_media_viewer (int? pos) {
		app.main_window.show_media_viewer (entity.url, pic.alternative_text, media_kind in VIDEO_TYPES, pic.paintable, pos);
	}

	public signal void on_any_attachment_click (string url) {}
}
