public class Tuba.Widgets.Attachment.Box : Adw.Bin {

	Gee.ArrayList<API.Attachment>? _list = null;
	public Gee.ArrayList<API.Attachment>? list {
		get {
			return _list;
		}
		set {
			_list = value;
			update ();
		}
	}

	#if GSTREAMER
		public bool has_thumbnailess_audio { get; private set; default=false; }
		public Gdk.Paintable? audio_fallback_paintable { get; set; default=null; }
	#endif

	private bool _has_spoiler = false;
	public bool has_spoiler {
		get {
			return _has_spoiler;
		}

		set {
			_has_spoiler = value;
			if (value) spoiler_revealed = false;
		}
	}

	private bool _spoiler_revealed = false;
	public bool spoiler_revealed {
		get {
			return _spoiler_revealed;
		}

		set {
			_spoiler_revealed = value;
			if (has_spoiler) {
				foreach (var attachment_w in attachment_widgets) {
					attachment_w.spoiler = !value;
				}
				reveal_btn.visible = value;
				reveal_text.visible = !value;
			}
		}
	}

	protected Adw.WrapBox box;
	protected Gtk.Button reveal_btn;
	protected Gtk.Label reveal_text;

	construct {
		visible = false;
		hexpand = true;

		box = new Adw.WrapBox () {
			line_homogeneous = true,
			child_spacing = 6,
			line_spacing = 6,
			justify = Adw.JustifyMode.FILL
		};

		reveal_btn = new Gtk.Button () {
			icon_name = "tuba-eye-not-looking-symbolic",
			// translators: Tooltip on a button that hides / blurs media marked as sensitive
			tooltip_text = _("Hide Media"),
			css_classes = { "osd", "circular" },
			halign = Gtk.Align.START,
			valign = Gtk.Align.START,
			margin_start = 6,
			margin_top = 6,
			visible = false
		};
		reveal_btn.clicked.connect (hide_spoilers);

		// translators: Label shown in front of blurred / sensitive media
		reveal_text = new Gtk.Label (_("Show Sensitive Content")) {
			wrap = true,
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			vexpand = true,
			css_classes = { "osd", "heading", "ttl-status-badge", "sensitive-label" },
			visible = false,
			can_target = false
		};

		var overlay = new Gtk.Overlay ();
		overlay.child = box;
		overlay.add_overlay (reveal_btn);
		overlay.add_overlay (reveal_text);

		child = overlay;
	}

	void hide_spoilers () {
		spoiler_revealed = false;
	}

	private Attachment.Image[] attachment_widgets;
	protected void update () {
		foreach (var t_aw in attachment_widgets) {
			box.remove (t_aw);
		}

		attachment_widgets = {};

		if (list == null || list.is_empty) {
			visible = false;
			return;
		}

		var single_attachment = list.size == 1;
		list.@foreach (item => {
			try {
				var widget = item.to_widget ();
				box.append (widget);
				attachment_widgets += ((Widgets.Attachment.Image) widget);
				((Widgets.Attachment.Image) widget).spoiler_revealed.connect (on_spoiler_reveal);

				if (single_attachment) {
					widget.height_request = 334;
				}

				((Widgets.Attachment.Image) widget).on_any_attachment_click.connect (open_all_attachments);

				#if GSTREAMER
					if (!this.has_thumbnailess_audio && ((Widgets.Attachment.Image) widget).media_kind == Tuba.Attachment.MediaType.AUDIO) {
						this.has_thumbnailess_audio = item.blurhash == null || item.blurhash == "" || ((Widgets.Attachment.Image) widget).pic.paintable == null;
					}
				#endif
			} catch (Oopsie e) {
				warning (@"Error updating attachments: $(e.message)");
			}
			return true;
		});

		visible = true;
		spoiler_revealed = false;
	}

	private void on_spoiler_reveal () {
		spoiler_revealed = true;
	}

	private void open_all_attachments (string url) {
		int attachment_length = attachment_widgets.length;
		for (int i = 0; i < attachment_length; i++) {
			bool? is_main = null;
			if (attachment_length > 1)
				is_main = attachment_widgets[i].entity.url == url;

			var paintable = attachment_widgets[i].pic.paintable;
			var stream = false;

			#if GSTREAMER
				if (attachment_widgets[i].media_kind == Tuba.Attachment.MediaType.AUDIO) {
					if (paintable == null) {
						paintable = this.audio_fallback_paintable;
					}
					stream = true;
				}
			#endif

			app.main_window.show_media_viewer (
				attachment_widgets[i].entity.url,
				attachment_widgets[i].media_kind,
				paintable,
				attachment_widgets[i],
				false,
				attachment_widgets[i].pic.alternative_text,
				null,
				attachment_widgets[i].entity.blurhash,
				stream,
				is_main,
				is_main == null
			);

			if (is_main == true) {
				app.main_window.reveal_media_viewer_manually (attachment_widgets[i]);
			}
		}
	}
}
