public class Tuba.Widgets.Attachment.Image : Widgets.Attachment.Item {
	const string[] ALLOWED_TYPES = {"IMAGE", "VIDEO", "GIFV", "AUDIO"};
	const string[] VIDEO_TYPES = {"GIFV", "VIDEO", "AUDIO"};

	protected Gtk.Picture pic;
	protected Gtk.Overlay media_overlay;

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

	void update_pic_content_fit () {
		pic.content_fit = settings.letterbox_media ? Gtk.ContentFit.CONTAIN : Gtk.ContentFit.COVER;
	}

	construct {
		pic = new Gtk.Picture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			keep_aspect_ratio = true,
			css_classes = {"attachment-picture"}
		};

		update_pic_content_fit ();
		settings.notify["letterbox-media"].connect (update_pic_content_fit);

		media_overlay = new Gtk.Overlay ();
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

	protected virtual void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
		if (is_loaded)
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
