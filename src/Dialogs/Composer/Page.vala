public class Tuba.ComposerPage : Gtk.Box {

	public string title { get; set; }
	public string icon_name { get; set; }
	public uint badge_number { get; set; default = 0; }
	public virtual bool can_publish { get; set; default = false; }
	public virtual bool edit_mode { get; set; default = false; }

	public weak Dialogs.Compose dialog;
	public Tuba.Dialogs.Compose.BasicStatus status;

	Gtk.ScrolledWindow scroller;
	protected Gtk.Box content;
	protected Gtk.ActionBar bottom_bar;

	private bool _action_bar_on_top = false;
	public bool action_bar_on_top {
		get {
			return _action_bar_on_top;
		}
		set {
			_action_bar_on_top = value;

			if (bottom_bar != null) {
				reorder_child_after (bottom_bar, value ? null : scroller);
			}
		}
	}

	~ComposerPage () {
		message (@"Destroying $title Page");
	}

	construct {
		orientation = Gtk.Orientation.VERTICAL;

		scroller = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true
		};
		append (scroller);

		content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		scroller.child = content;

		bottom_bar = new Gtk.ActionBar () {
			visible = false
		};

		if (action_bar_on_top) {
			prepend (bottom_bar);
		} else {
			append (bottom_bar);
		}
	}

	protected void add_button (Gtk.Widget widget) {
		bottom_bar.pack_start (widget);

		widget.add_css_class ("flat");
		for (var w = widget.get_first_child (); w != null; w = w.get_next_sibling ()) {
			w.add_css_class ("flat");
		}

		bottom_bar.show ();
	}

	public virtual void on_build () {}

	// Entity -> UI state
	public virtual void on_pull () {}

	// UI state -> Entity
	public virtual void on_push () {}

	public virtual void on_modify_body (Json.Builder builder) {}

}
