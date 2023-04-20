using Gtk;

public class Tuba.ComposerPage : Gtk.Box {

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

	protected void add_button (Widget widget, ActionBar? t_action_bar = null, bool end = false) {
		// setting bottom_bar as default value for t_action_bar
		// causes compiler errors
		var bar = t_action_bar == null ? bottom_bar : t_action_bar;
		if (end) {
			bar.pack_end (widget);
		} else {
			bar.pack_start (widget);
		}

		widget.add_css_class ("flat");
		for (var w = widget.get_first_child (); w != null; w = w.get_next_sibling ()) {
			w.add_css_class ("flat");
		}

		bar.show ();
	}

	protected ActionBar add_top_actionbar () {
		var t_bar = new ActionBar () {
			visible = false
		};
		prepend (t_bar);
		return t_bar;
	}

	public virtual void on_build (Dialogs.Compose dialog, API.Status status) {
		this.dialog = dialog;
		this.status = status;
	}

	// Entity -> UI state
	public virtual void on_pull () {}

	// UI state -> Entity
	public virtual void on_push () {}

	public virtual void on_modify_req (Request req) {}

}
