public class Tuba.Widgets.Attachment.Image : Widgets.Attachment.Item {
	public Widgets.FocusPicture pic { get; private set; }
	protected Gtk.Overlay media_overlay;

	private bool _spoiler = false;
	public bool spoiler {
		get {
			return _spoiler;
		}

		set {
			_spoiler = value;
			pic.spoilered = value;

			if (media_icon != null) media_icon.visible = !value;
		}
	}

	void update_pic_content_fit () {
		pic.content_fit = settings.letterbox_media || (entity != null && entity.tuba_is_report) ? Gtk.ContentFit.CONTAIN : Gtk.ContentFit.COVER;
	}

	construct {
		pic = new Widgets.FocusPicture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
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

		if (media_kind.is_video () || media_kind == UNKNOWN) {
			media_icon = new Gtk.Image () {
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};

			if (media_kind == UNKNOWN) {
				media_icon.icon_name = "tuba-paper-symbolic";
			} else if (media_kind != Tuba.Attachment.MediaType.AUDIO) {
				media_icon.css_classes = { "osd", "tuba-circular", "min-size-64" };
				media_icon.icon_name = "media-playback-start-symbolic";
			} else {
				pic_paintable_id = pic.notify["paintable"].connect (on_audio_paintable_notify);
				media_icon.icon_name = "tuba-music-note-symbolic";
			}

			media_overlay.add_overlay (media_icon);

			// Doesn't get applied sometimes when set above
			media_icon.icon_size = Gtk.IconSize.LARGE;
		}

		if (entity.meta != null && entity.meta.focus != null) {
			pic.focus_x = entity.meta.focus.x;
			pic.focus_y = entity.meta.focus.y;
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
			media_icon.css_classes = { "osd", "tuba-circular", "min-size-64" };
		}
		media_icon.icon_size = Gtk.IconSize.LARGE;
	}

	protected override void copy_media () {
		debug ("Begin copy-media action");
		Utils.Host.download.begin (entity.url, (obj, res) => {
			try {
				string path = Utils.Host.download.end (res);

				Gdk.Texture texture = Gdk.Texture.from_filename (path);
				if (texture == null) return;

				Gdk.Clipboard clipboard = Gdk.Display.get_default ().get_clipboard ();
				clipboard.set_texture (texture);
				// translators: toast shown after successfully copying an image to clipboard
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
		if (pic.spoilered) {
			spoiler_revealed ();
			return;
		}

		if (media_kind != Tuba.Attachment.MediaType.UNKNOWN) {
			on_any_attachment_click (entity.url);
		} else { // Fallback
			on_remote_fetch_media.begin ();
		}
	}

	private async void on_remote_fetch_media () {
		debug (@"Loading remote media $(entity.remote_url == null ? entity.url : entity.remote_url)");

		if (settings.fetch_remote_media_reminder && entity.remote_url != null) {
			var checkbutton = new Gtk.CheckButton () {
				label = _("Don't remind me again"),
				halign = Gtk.Align.CENTER
			};
			var res = yield app.question (
				// translators: dialog title shown when asking the user to fetch media from a remote
				//				instance/server. Load = fetch = download, remote = external = not in
				//				user's instance, media = attachments = photos/videos/music/files
				{"Load remote media?", false},
				// translators: dialog subtitle, shown when asking the user to fetch media from a
				//				remote instance/server. "Your instance" means the server the active
				//				user's account is on. "Proxied" means that it handles it locally,
				//				without the user connecting to the remote instance. By "can't handle
				//				this attachment", it means it's a file like a PDF and the user's
				//				instance doesn't know what to do with it. By "fetch" it means to
				//				download it from the server the author is on. The variable is a
				//				string app name (Tuba).
				{_("Your instance hasn't proxied or can't handle this attachment. %s can fetch it directly from the remote instance however.").printf (Build.NAME), false},
				app.main_window,
				{ { "Load", Adw.ResponseAppearance.SUGGESTED }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				checkbutton,
				false
			);

			// we want to have "dont remind me again" apply the last selected
			// option. So if it's CLOSE or NO, set it to false
			if (res != Tuba.Application.QuestionAnswer.YES) {
				settings.fetch_remote_media_default = false;
				return;
			}

			settings.fetch_remote_media_default = true;
			if (checkbutton.active) settings.fetch_remote_media_reminder = false;
		}

		var media_type = entity.remote_url == null ? null : media_type_from_url (entity.remote_url);
		if (settings.fetch_remote_media_default && media_type != null) {
			bool stream = false;
			#if GSTREAMER
				if (media_type == AUDIO) {
					stream = true;
				}
			#endif

			app.main_window.show_media_viewer (
				entity.remote_url,
				media_type,
				null,
				null,
				false,
				entity.description,
				null,
				entity.blurhash,
				stream
			);
			return;
		}

		base.on_click ();
	}

	private Tuba.Attachment.MediaType? media_type_from_url (string url) {
		string basename = GLib.Path.get_basename (url);
		string? content_type = GLib.ContentType.guess (basename, null, null);
		if (content_type == null) return null;

		string? mime = GLib.ContentType.get_mime_type (content_type);
		if (mime == null) return null;

		if (mime.has_prefix ("audio/")) return AUDIO;
		if (mime.has_prefix ("image/")) return IMAGE;
		if (mime.has_prefix ("video/")) return VIDEO;

		return null;
	}

	public signal void on_any_attachment_click (string url) {}
}
