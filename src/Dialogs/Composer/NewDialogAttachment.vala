public class Tuba.Dialogs.Components.Attachment : Adw.Bin {
	public signal void switch_place (Attachment with);
	public signal void delete_me ();
	public signal void edit ();

	public class AltIndicator : Gtk.Box {
		private bool _valid = false;
		public bool valid {
			get { return _valid; }
			set {
				_valid = value;
				update_valid ();
			}
		}

		static construct {
			set_accessible_role (Gtk.AccessibleRole.PRESENTATION);
		}

		Gtk.Image icon;
		construct {
			this.overflow = HIDDEN;
			this.orientation = HORIZONTAL;
			this.spacing = 3;
			this.can_focus = this.focusable = false;
			this.css_classes = { "alt-indicator" };
			icon = new Gtk.Image.from_icon_name ("tuba-cross-large-symbolic");

			this.append (new Gtk.Label ("ALT"));
			this.append (icon);

			update_valid ();
		}

		private void update_valid () {
			if (this.valid) {
				if (this.has_css_class ("error")) this.remove_css_class ("error");
				if (!this.has_css_class ("success")) this.add_css_class ("success");
				icon.icon_name = "tuba-check-plain-symbolic";
			} else {
				if (!this.has_css_class ("error")) this.add_css_class ("error");
				if (this.has_css_class ("success")) this.remove_css_class ("success");
				icon.icon_name = "tuba-cross-large-symbolic";
			}
		}
	}

	public enum MediaType {
		IMAGE,
		VIDEO,
		AUDIO;

		public static MediaType from_string (string kind) {
			switch (kind.down ()) {
				case "audio":
					return AUDIO;
				case "video":
				case "gifv":
					return VIDEO;
				default:
					return IMAGE;
			}
		}
	}

	private MediaType _kind = MediaType.IMAGE;
	public MediaType kind {
		get { return _kind; }
		private set {
			_kind = value;
			switch (value) {
				case AUDIO:
					media_icon.icon_name = "tuba-music-note-symbolic";
					media_icon.visible = true;
					break;
				case VIDEO:
					media_icon.icon_name = "media-playback-start-symbolic";
					media_icon.visible = true;
					break;
				default:
					media_icon.visible = false;
					break;
			}
			media_icon.icon_size = Gtk.IconSize.LARGE;
		}
	}

	public bool edit_mode { get; set; default = false; }
	public string? media_id { get; set; default = null; }
	public Gdk.Paintable? paintable {
		get { return picture.paintable; }
		set {
			picture.paintable = value;
		}
	}

	private bool _done = false;
	public bool done {
		get { return _done; }
		private set {
			_done =
			delete_button.visible =
			alt_button.visible =
			alt_indicator.visible = value;

			progress_label.visible = !value;
		}
	}

	private double _progress = 0;
	private double progress {
		get { return _progress; }
		set {
			progress_animation.value_from = progress_animation.state == PLAYING ? progress_animation.value : _progress;
			_progress = value;
			progress_label.label = @"$((int) (value * 100))%";
			progress_animation.value_to = value;
			progress_animation.play ();
		}
	}

	public double pos_x {
		get { return picture.focus_x; }
		set {
			picture.focus_x = value;
		}
	}

	public double pos_y {
		get { return picture.focus_y; }
		set {
			picture.focus_y = value;
		}
	}

	private string _alt_text = "";
	public string alt_text {
		get {
			return _alt_text;
		}

		set {
			_alt_text = value;
			alt_indicator.valid = value != "";
		}
	}

	public GLib.File? file { get; set; default = null; }

	Adw.TimedAnimation opacity_animation;
	Widgets.FocusPicture picture;
	Gtk.Button delete_button;
	Gtk.Button alt_button;
	AltIndicator alt_indicator;
	Gtk.Label progress_label;
	Gtk.Image media_icon;
	Adw.TimedAnimation animation;
	Adw.TimedAnimation progress_animation;
	Components.DropOverlay drop_overlay;
	Gdk.RGBA color = { 120 / 255.0f, 174 / 255.0f, 237 / 255.0f, 0.5f };
	construct {
		this.css_classes = { "composer-attachment" };
		this.overflow = HIDDEN;
		this.opacity = 0;
		progress_animation = new Adw.TimedAnimation (this, 0, 1, 200, new Adw.CallbackAnimationTarget (progress_animation_cb));
		animation = new Adw.TimedAnimation (this, 0, 1, 250, new Adw.PropertyAnimationTarget (this, "opacity"));
		animation.done.connect (on_animation_end);

		var default_sm = Adw.StyleManager.get_default ();
		if (default_sm.system_supports_accent_colors) {
			default_sm.notify["accent-color-rgba"].connect (update_accent_color);
			update_accent_color ();
		} else {
			color = {
				120 / 255.0f,
				174 / 255.0f,
				237 / 255.0f,
				0.5f
			};
		}

		picture = new Widgets.FocusPicture () {
			hexpand = true,
			vexpand = true,
			can_shrink = true,
			content_fit = Gtk.ContentFit.COVER
		};

		var overlay = new Gtk.Overlay () {
			vexpand = true,
			hexpand = true,
			child = picture
		};

		delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			halign = END,
			valign = START,
			margin_top = 6,
			margin_end = 6,
			css_classes = { "osd", "circular" },
			visible = false
		};
		delete_button.clicked.connect (on_delete);

		alt_button = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
			halign = END,
			valign = END,
			margin_bottom = 6,
			margin_end = 6,
			css_classes = { "osd", "circular" },
			visible = false
		};
		alt_button.clicked.connect (on_edit_clicked);

		alt_indicator = new AltIndicator () {
			halign = START,
			valign = END,
			margin_bottom = 6,
			margin_start = 6,
			visible = false
		};

		progress_label = new Gtk.Label ("0%") {
			halign = CENTER,
			valign = CENTER,
			visible = true,
			css_classes = { "font-bold", "numeric" }
		};

		media_icon = new Gtk.Image.from_icon_name ("media-playback-start-symbolic") {
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			visible = false,
			css_classes = { "osd", "circular", "attachment-overlay-icon" }
		};

		overlay.add_overlay (delete_button);
		overlay.add_overlay (alt_button);
		overlay.add_overlay (alt_indicator);
		overlay.add_overlay (progress_label);
		overlay.add_overlay (media_icon);

		drop_overlay = new Components.DropOverlay () {
			compact = true,
			overlay_child = overlay,
			icon_name = ""
		};
		this.child = drop_overlay;
		this.height_request = 120;

		var drag_source_controller = new Gtk.DragSource () {
			actions = MOVE
		};
		drag_source_controller.prepare.connect (on_drag_prepare);
		drag_source_controller.drag_begin.connect (on_drag_begin);
		drag_source_controller.drag_end.connect (on_drag_end);
		drag_source_controller.drag_cancel.connect (on_drag_cancel);
		this.add_controller (drag_source_controller);

		var drop_target_controller = new Gtk.DropTarget (typeof (Attachment), MOVE);
		drop_target_controller.enter.connect (on_drop_enter);
		drop_target_controller.leave.connect (on_drop_leave);
		drop_target_controller.drop.connect (on_drop);
		this.add_controller (drop_target_controller);

		// DnD
		opacity_animation = new Adw.TimedAnimation (this, 0, 1, 200, new Adw.PropertyAnimationTarget (this, "opacity")) {
			easing = Adw.Easing.LINEAR
		};
	}

	private void progress_animation_cb () {
		this.queue_draw ();
	}

	public void play_animation (bool reverse = false) {
		animation.reverse = reverse;
		animation.play ();
	}

	private void on_animation_end () {
		if (animation.value == 0) delete_me ();
	}

	private void on_edit_clicked () {
		edit ();
	}

	public Attachment.from_paintable (Gdk.Paintable? paintable) {
		picture.paintable = paintable;
	}

	private void update_accent_color () {
		color = Adw.StyleManager.get_default ().get_accent_color_rgba ();
		color.alpha = 0.5f;
		if (this.progress != 0) this.queue_draw ();
	}

	double drag_x = 0;
	double drag_y = 0;
	private Gdk.ContentProvider? on_drag_prepare (double x, double y) {
		if (!this.done) return null;

		drag_x = x;
		drag_y = y;

		Value value = Value (typeof (Attachment));
		value.set_object (this);

		return new Gdk.ContentProvider.for_value (value);
	}

	bool being_dragged = false;
	private void on_drag_begin (Gtk.DragSource ds_controller, Gdk.Drag drag) {
		ds_controller.set_icon ((new Gtk.WidgetPaintable (this)).get_current_image (), (int) drag_x, (int) drag_y);
		being_dragged = true;

		animate_opacity (true);
	}

	private void on_drag_end (Gdk.Drag drag, bool delete_data) {
		being_dragged = false;
		animate_opacity ();
	}

	private bool on_drag_cancel (Gdk.Drag drag, Gdk.DragCancelReason reason) {
		being_dragged = false;
		animate_opacity ();
		return false;
	}

	private bool on_drop (Gtk.DropTarget dt_controller, GLib.Value value, double x, double y) {
		drop_overlay.dropping = false;
		if (!this.done || dt_controller.get_value () == null || dt_controller.get_value ().get_object () == this) return false;
		switch_place (dt_controller.get_value ().get_object () as Attachment);
		return true;
	}

	private Gdk.DragAction on_drop_enter (double x, double y) {
		drop_overlay.dropping = true && !being_dragged;
		return Gdk.DragAction.MOVE;
	}

	private void on_drop_leave () {
		drop_overlay.dropping = false;
	}

	private void animate_opacity (bool hide = false) {
		if (opacity_animation.state == PLAYING) opacity_animation.pause ();

		opacity_animation.value_from = opacity_animation.value;
		opacity_animation.value_to = hide ? 0 : 1;
		opacity_animation.play ();
	}

	// TODO
	private bool upload_lock = false;
	public async void upload (GLib.File file) throws Error {
		bytes_written = 0;
		total_bytes = 0;
		upload_lock = true;

		Bytes buffer;
		string mime;
		string uri = file.get_uri ();
		debug (@"Uploading new media: $(uri)…");

		{
			uint8[] contents;
			try {
				file.load_contents (null, out contents, null);
				GLib.FileInfo type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
				mime = type.get_content_type ();
			} catch (Error e) {
				upload_lock = false;
				throw new Oopsie.USER ("Can't open file %s:\n%s".printf (uri, e.message));
			}
			buffer = new Bytes.take (contents);
			total_bytes = buffer.get_size ();
		}

		var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);

		var msg = new Soup.Message.from_multipart (@"$(accounts.active.instance)/api/v1/media", multipart);
		msg.request_headers.append ("Authorization", @"Bearer $(accounts.active.access_token)");
		msg.wrote_body_data.connect (on_upload_bytes_written);

		string? error = null;
		InputStream? in_stream = null;
		network.queue (msg, null,
			(t_is) => {
				in_stream = t_is;
				upload.callback ();
			},
			(code, reason) => {
				error = reason;
				upload.callback ();
			}
		);
		yield;

		if (error != null || in_stream == null) {
			upload_lock = false;
			throw new Oopsie.INSTANCE (error);
		}
		this.progress = 1;

		this.file = file;
		var parser = Network.get_parser_from_inputstream (in_stream);
		var node = network.parse_node (parser);
		var entity = accounts.active.create_entity<API.Attachment> (node);
		this.media_id = entity.id;

		this.kind = MediaType.from_string (entity.kind);
		var working_loader = new AttachmentThumbnailer (uri, this.kind);
		working_loader.done.connect (on_done);
		new GLib.Thread<void>.try (@"Attachment Thumbnail $uri", working_loader.fetch);

		debug (@"OK! ID $(entity.id)");
		this.done = true;

		upload_lock = false;
	}

	private class AttachmentThumbnailer : GLib.Object {
		public signal void done (Gdk.Paintable? paintable);
		File file;
		Attachment.MediaType kind;
		public AttachmentThumbnailer (string file_uri, Attachment.MediaType kind) {
			this.file = File.new_for_uri (file_uri);
			this.kind = kind;
		}

		public void fetch () {
			string file_uri = this.file.get_uri ();
			debug (@"Generating thumbnail for $file_uri");

			try {
				switch (kind) {
					case IMAGE:
						done (Gdk.Texture.from_file (this.file));
						break;
					case VIDEO:
						#if GSTREAMER
							var playbin = Gst.ElementFactory.make ("playbin");
							playbin.set ("video-sink", Gst.ElementFactory.make ("fakesink"));
							playbin.set ("audio-sink", Gst.ElementFactory.make ("fakesink"));
							playbin.set_property ("uri", file_uri);

							playbin.set_state (PAUSED);
							playbin.get_state (null, null, Gst.CLOCK_TIME_NONE);

							if (!playbin.seek_simple (TIME, FLUSH, 1 * Gst.SECOND)) return;
							playbin.get_state (null, null, Gst.CLOCK_TIME_NONE);

							Gst.Sample? sample = null;
							var cups = Gst.Caps.from_string ("image/png");
							Signal.emit_by_name (playbin, "convert-sample", cups, out sample);
							if (sample == null) return;

							Gst.Buffer? buffer = sample.get_buffer ();
							if (buffer == null) return;

							Gst.MapInfo map_info;
							if (!buffer.map (out map_info, READ)) return;

							done (Gdk.Texture.from_bytes (new Bytes.take (map_info.data)));
						#else
							done (null);
						#endif
						break;
					default:
						done (null);
						break;
				}
			} catch (Error e) {
				critical (@"Error while generating thumbnail: $(e.message)");
				done (null);
			}
		}
	}

	private void on_done (Gdk.Paintable? paintable) {
		this.paintable = paintable;
	}

	uint bytes_written = 0;
	size_t total_bytes = 0;
	private void on_upload_bytes_written (Soup.Message msg, uint chunk) {
		bytes_written += chunk;
		this.progress = ((double) bytes_written / (double) total_bytes).clamp (0, 0.999999999);
	}

	public override void snapshot (Gtk.Snapshot snapshot) {
		if (!this.done) {
			snapshot.append_color (
				color,
				Graphene.Rect () {
					origin = Graphene.Point () {
						x = 0,
						y = 0
					},
					size = Graphene.Size () {
						height = this.get_height (),
						width = (float) (this.get_width () * this.progress_animation.value)
					}
				}
			);
		}

		base.snapshot (snapshot);
	}

	private void on_delete () {
		play_animation (true);
	}

	public void preload (string media_id, string url, string? preview, MediaType kind) {
		this.kind = kind;
		this.media_id = media_id;
		switch (this.kind) {
			case AUDIO:
			case VIDEO:
				if (preview == null) {
					var working_loader = new AttachmentThumbnailer (url, this.kind);
					working_loader.done.connect (on_done);
					new GLib.Thread<void>.try (@"Attachment Thumbnail $url", working_loader.fetch);
				} else {
					Tuba.Helper.Image.request_paintable (preview, null, false, on_done);
				}

				this.file = GLib.File.new_for_uri (url);
				break;
			default:
				Tuba.Helper.Image.request_paintable (url, null, false, on_done);
				break;
		}

		this.done = true;
	}

	public void saved (float pos_x, float pos_y, string alt_text) {
		this.pos_x = (double) pos_x;
		this.pos_y = (double) pos_y;
		this.alt_text = alt_text;
	}
}
