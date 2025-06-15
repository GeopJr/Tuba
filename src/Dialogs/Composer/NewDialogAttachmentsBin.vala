public class Tuba.Dialogs.Components.AttachmentsBin : Gtk.Grid, Attachable {
	construct {
		this.column_spacing = this.row_spacing = 12;
		this.row_homogeneous = this.column_homogeneous = true;

		for (int i = 0; i < 4; i ++) {
			var a = new Components.Attachment ();
			a.switch_place.connect (on_switch_place);
			a.add_css_class (i % 2 == 0 ? "error" : "success");
			this.attach (a, 0, i);

			var b = new Components.Attachment ();
			b.switch_place.connect (on_switch_place);
			b.add_css_class (i % 2 != 0 ? "error" : "success");
			this.attach (b, 1, i);

			//  this.attach (new Components.Attachment (), 0, i);
			//  if (i != 3) this.attach (new Components.Attachment (), 1, i);
		}
	}

	private void on_switch_place (Components.Attachment from, Components.Attachment to) {
		int from_column;
		int from_row;
		this.query_child (from, out from_column, out from_row, null, null);

		int to_column;
		int to_row;
		this.query_child (to, out to_column, out to_row, null, null);

		this.remove (from);
		this.remove (to);

		this.attach (to, from_column, from_row);
		this.attach (from, to_column, to_row);
	}
}
