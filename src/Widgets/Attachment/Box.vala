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

	protected void update () {
		// box.clear_all ();

		if (list == null || list.is_empty) {
			visible = false;
			return;
		}

		list.@foreach (item => {
			try {
				var widget = item.to_widget ();
				box.insert (widget, -1);
			} catch (Oopsie e) {
				warning(@"Error updating attachements: $(e.message)");
			}
			return true;
		});

		box.max_children_per_line = 2;
		box.min_children_per_line = 2;
		// if (list.size > 1) {
		// 	box.max_children_per_line = 2;
		// }

		visible = true;
	}

}
