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

	protected Gtk.FlowBox box;
	protected Gtk.Button reveal_btn;
	protected Gtk.Label reveal_text;

	construct {
		visible = false;
		hexpand = true;

		box = new Gtk.FlowBox () {
			homogeneous = true,
			activate_on_single_click = true,
			column_spacing = 6,
			row_spacing = 6,
			selection_mode = Gtk.SelectionMode.NONE
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
				var flowboxchild = new Gtk.FlowBoxChild () {
					child = widget,
					focusable = false
				};
				box.insert (flowboxchild, -1);
				attachment_widgets += ((Widgets.Attachment.Image) widget);
				((Widgets.Attachment.Image) widget).spoiler_revealed.connect (on_spoiler_reveal);

				if (single_attachment) {
					widget.height_request = 334;
				}

				((Widgets.Attachment.Image) widget).on_any_attachment_click.connect (() => open_all_attachments (item.url));
			} catch (Oopsie e) {
				warning (@"Error updating attachments: $(e.message)");
			}
			return true;
		});

		if (single_attachment) {
			box.max_children_per_line = 1;
			box.min_children_per_line = 1;
		} else {
			box.max_children_per_line = 2;
			box.min_children_per_line = 2;
		}

		visible = true;
		spoiler_revealed = false;
	}

	private void on_spoiler_reveal () {
		spoiler_revealed = true;
	}

	private void open_all_attachments (string url) {
		var i = 0;
		var main = 0;
		foreach (var at_widget in attachment_widgets) {
			if (at_widget.entity.url != url) {
				at_widget.load_image_in_media_viewer (i);
			} else {
				main = i;
			};
			i += 1;
		}

		if (i > 0) {
			app.main_window.scroll_media_viewer (main);
		}
	}
}
