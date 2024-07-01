public class Tuba.Widgets.Attachment.Image : Widgets.Attachment.Item {
	public Gtk.Picture pic { get; private set; }
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
		pic.content_fit = settings.letterbox_media || (entity != null && entity.tuba_is_report) ? Gtk.ContentFit.CONTAIN : Gtk.ContentFit.COVER;
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
	ulong pic_paintable_id = 0;
	protected override void on_rebind () {
		base.on_rebind ();
		update_pic_content_fit ();

		if (entity == null) {
			pic.alternative_text = null;
		} else if (entity.tuba_translated_alt_text != null) {
			pic.alternative_text = entity.tuba_translated_alt_text;
		} else {
			pic.alternative_text = entity.description;
		}

		if (pic_paintable_id != 0) {
			pic.disconnect (pic_paintable_id);
			pic_paintable_id = 0;
		}

		if (media_kind.is_video ()) {
			media_icon = new Gtk.Image () {
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};

			if (media_kind != Tuba.Attachment.MediaType.AUDIO) {
				media_icon.css_classes = { "osd", "circular", "attachment-overlay-icon" };
				media_icon.icon_name = "media-playback-start-symbolic";
			} else {
				pic_paintable_id = pic.notify["paintable"].connect (on_audio_paintable_notify);
				media_icon.icon_name = "tuba-music-note-symbolic";
			}

			media_overlay.add_overlay (media_icon);

			// Doesn't get applied sometimes when set above
			media_icon.icon_size = Gtk.IconSize.LARGE;
		}

		Tuba.Helper.Image.request_paintable (entity.preview_url, entity.blurhash, (entity != null && entity.tuba_is_report), on_cache_response);
		copy_media_simple_action.set_enabled (media_kind.can_copy ());
	}

	private void on_audio_paintable_notify () {
		if (media_icon == null) return;

		// toggle icon size so it applies
		media_icon.icon_size = Gtk.IconSize.NORMAL;
		if (pic.paintable == null) {
			media_icon.css_classes = {};
		} else {
			media_icon.css_classes = { "osd", "circular", "attachment-overlay-icon" };
		}
		media_icon.icon_size = Gtk.IconSize.LARGE;
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
				app.toast (_("Copied image to clipboard"));
			} catch (Error e) {
				app.toast ("%s: %s".printf (_("Error"), e.message));
			}

			debug ("End copy-media action");
		});
	}

	protected virtual void on_cache_response (Gdk.Paintable? data) {
		pic.paintable = data;
	}

	public signal void spoiler_revealed ();
	protected override void on_click () {
		if (pic.has_css_class ("spoilered-attachment")) {
			spoiler_revealed ();
			return;
		}

		if (media_kind != Tuba.Attachment.MediaType.UNKNOWN) {
			on_any_attachment_click (entity.url);
		} else { // Fallback
			base.on_click ();
		}
	}

	public signal void on_any_attachment_click (string url) {}
}
