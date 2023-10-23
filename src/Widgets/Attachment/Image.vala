public class Tuba.Widgets.Attachment.Image : Widgets.Attachment.Item {
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

		Tuba.ImageCache.request_paintable (entity.preview_url, on_cache_response);

		if (media_kind.is_video ()) {
			media_icon = new Gtk.Image () {
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};

			if (media_kind != Tuba.Attachment.MediaType.AUDIO) {
				media_icon.css_classes = { "osd", "circular", "attachment-overlay-icon" };
				media_icon.icon_name = "media-playback-start-symbolic";
			} else {
				media_icon.icon_name = "tuba-music-note-symbolic";
			}

			media_overlay.add_overlay (media_icon);

			// Doesn't get applied sometimes when set above
			media_icon.icon_size = Gtk.IconSize.LARGE;
		}

		copy_media_simple_action.set_enabled (media_kind.can_copy ());
	}

	protected override void copy_media () {
		debug ("Begin copy-media action");
		Host.download.begin (entity.url, (obj, res) => {
			try {
				string path = Host.download.end (res);

				Gdk.Texture texture = Gdk.Texture.from_filename (path);
				if (texture == null) return;

				Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
				clipboard.set_texture (texture);
			} catch (Error e) {
				var dlg = app.inform (_("Error"), e.message);
				dlg.present ();
			}

			debug ("End copy-media action");
		});
	}

	protected virtual void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
		if (is_loaded) {
			pic.paintable = data;
		} else if (settings.use_blurhash) {
			pic.paintable = Tuba.BlurhashCache.lookup_or_decode (entity.blurhash);
		}
	}

	public signal void spoiler_revealed ();
	protected override void on_click () {
		if (pic.has_css_class ("spoilered-attachment")) {
			spoiler_revealed ();
			return;
		}

		if (media_kind != Tuba.Attachment.MediaType.UNKNOWN) {
			load_image_in_media_viewer (null);
			on_any_attachment_click (entity.url);
		} else { // Fallback
			base.on_click ();
		}
	}

	public void load_image_in_media_viewer (int? pos) {
		app.main_window.show_media_viewer (entity.url, media_kind, pic.paintable, pos, this, false, pic.alternative_text);
	}

	public signal void on_any_attachment_click (string url) {}
}
