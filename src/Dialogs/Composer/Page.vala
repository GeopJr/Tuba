using Gtk;

public class Tootle.ComposerPage : Gtk.Box {

	public string title { get; set; }
	public string icon_name { get; set; }
	public uint badge_number { get; set; default = 0; }

	protected weak Dialogs.Compose dialog;
	protected weak API.Status status;

	ScrolledWindow scroller;
	protected Box content;
	protected ActionBar bottom_bar;

	construct {
		orientation = Orientation.VERTICAL;

		scroller = new ScrolledWindow () {
			hexpand = true,
			vexpand = true
		};
		append (scroller);

		content = new Box (Orientation.VERTICAL, 0);
		scroller.child = content;

		bottom_bar = new ActionBar () {
			visible = false
		};
		append (bottom_bar);
	}

	protected void add_button (Widget widget) {
		bottom_bar.pack_start (widget);
		widget.add_css_class ("flat");
		for (var w = widget.get_first_child (); w != null; w = w.get_next_sibling ()) {
			w.add_css_class ("flat");
		}
		bottom_bar.show ();
	}

	// This is used to populate the UI with the status entity data
	public virtual void on_build (Dialogs.Compose dialog, API.Status status) {
		this.dialog = dialog;
		this.status = status;
	}

	// This is used to push data back to the status entity
	public virtual void on_sync () {}

	public virtual void on_modify_req (Request req) {}

}
