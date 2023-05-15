using Gtk;
using GLib;
using Gee;

public class Tuba.Widgets.Attachment.Box : Adw.Bin {

	ArrayList<API.Attachment>? _list = null;
	public ArrayList<API.Attachment>? list {
		get {
			return _list;
		}
		set {
			_list = value;
			update ();
		}
	}

	protected Gtk.FlowBox box;

	construct {
		visible = false;
		hexpand = true;

		box = new FlowBox () {
			homogeneous = true,
			activate_on_single_click = true,
			column_spacing = 6,
			row_spacing = 6,
			selection_mode = SelectionMode.NONE
		};
		child = box;
	}

	private Attachment.Image[] attachment_widgets;
	protected void update () {
		// box.clear_all ();
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

				if (single_attachment) {
					if (item != null && item.meta != null && item.meta.small != null && item.meta.small.width != 0 && item.meta.small.height != 0 && item.meta.small.aspect != 0.0f) {
						//  var is_landscape = item.meta.small.width > item.meta.small.height;
						//  widget.height_request = 
					} else {
						widget.height_request = 384;
					}
				}
				((Widgets.Attachment.Image) widget).on_any_attachment_click.connect (() => open_all_attachments(item.url));
			} catch (Oopsie e) {
				warning(@"Error updating attachments: $(e.message)");
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
		// if (list.size > 1) {
		// 	box.max_children_per_line = 2;
		// }

		visible = true;
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
			app.main_window.scroll_media_viewer(main);
		}
	}
}
