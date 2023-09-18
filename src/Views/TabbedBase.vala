public class Tuba.Views.TabbedBase : Views.Base {

	static int id_counter = 0;

	protected Adw.ViewSwitcher switcher;
	protected Adw.ViewSwitcherBar switcher_bar;
	protected Adw.ViewStack stack;
	protected Adw.WindowTitle title_header;

	public void change_page_to_named (string page_name) {
		stack.visible_child_name = page_name;
	}

	Views.Base? last_view = null;
	Views.Base[] views = {};

	construct {
		base_status = null;

		//  var states_box = states.get_parent () as Gtk.Box;
		//  if (states_box != null)
		//  	states_box.remove (states);
		//  view.remove_css_class ("ttl-view");

		scrolled_overlay.child = null;

		var scrolled_overlay_box = scrolled_overlay.get_parent () as Gtk.Box;
		if (scrolled_overlay_box != null)
			scrolled_overlay_box.remove (scrolled_overlay);
		toolbar_view.content = states;

		stack = new Adw.ViewStack () { vexpand = true };
		stack.notify["visible-child"].connect (on_view_switched);
		scrolled.child = stack;

		switcher_bar.stack = switcher.stack = stack;
	}

	~TabbedBase () {
		debug ("Destroying TabbedBase");

		foreach (var tab in views) {
			stack.remove (tab);
			tab.dispose ();
		}
		views = {};
	}

	public override void build_header () {
		switcher = new Adw.ViewSwitcher () { policy = Adw.ViewSwitcherPolicy.WIDE };
		header.title_widget = switcher;

		switcher_bar = new Adw.ViewSwitcherBar ();
		toolbar_view.add_bottom_bar (switcher_bar);

		title_header = new Adw.WindowTitle (label, "");
		bind_property ("label", title_header, "title", BindingFlags.SYNC_CREATE);

		var condition = new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			550, Adw.LengthUnit.SP
		);
		var breakpoint = new Adw.Breakpoint (condition);
		breakpoint.add_setter (header, "title-widget", title_header);
		breakpoint.add_setter (switcher_bar, "reveal", true);
		add_breakpoint (breakpoint);
	}

	public void add_tab (Views.Base view) {
		id_counter++;
		view.content_box.add_css_class ("no-transition");
		views += view;
		var page = stack.add_titled (view, id_counter.to_string (), view.label);
		view.bind_property ("icon", page, "icon-name", BindingFlags.SYNC_CREATE);
		view.bind_property ("needs-attention", page, "needs-attention", BindingFlags.SYNC_CREATE);
		view.bind_property ("badge-number", page, "badge-number", BindingFlags.SYNC_CREATE);
		view.header.hide ();
	}

	public Views.ContentBase add_list_tab (string label, string icon) {
		var tab = new Views.ContentBase ();
		tab.label = label;
		tab.icon = icon;

		add_tab (tab);

		return tab;
	}

	public Views.ContentBase add_timeline_tab (string label, string icon, string url, Type accepts) {
		var tab = new Views.Timeline () {
			url = url,
			label = label,
			icon = icon,
			accepts = accepts
		};
		tab.label = label;
		tab.icon = icon;

		add_tab (tab);

		return tab;
	}

	public delegate void TabCB (Views.ContentBase tab);
	public void foreach_tab (TabCB cb) {
		for (var w = stack.get_first_child (); w != null; w = w.get_next_sibling ()) {
			var tab = w as Views.ContentBase;
			if (tab != null)
				cb (tab);
		}
	}

	public override void clear () {
		foreach_tab (tab => tab.clear ());
		on_content_changed ();
	}

	// TODO: Why did I write this? What does it do??? Why does it crash????
	public override void on_content_changed () {
		// var empty = true;
		foreach_tab (tab => {
			// tab.visible = !tab.empty;
			// if (tab.visible)
			// 	empty = false;

			tab.on_content_changed ();
		});
		base_status = null;

		// if (empty) {
		// 	state = "status";
		// 	status_title = STATUS_EMPTY;
		// }
		// else {
		// 	state = "content";
		// }
	}

	public override void scroll_page (bool up = false) {
		var c_scrolled = stack.visible_child as Views.Base;
		if (c_scrolled != null)
			c_scrolled.scroll_page (up);
	}

	protected virtual void on_view_switched () {
		var view = stack.visible_child as Views.Base;
		if (view.content_box.has_css_class ("no-transition")) {
			Timeout.add_once (200, () => {
				last_view.content_box.remove_css_class ("no-transition");
			});
		}

		if (last_view != null) {
			last_view.current = false;
		}

		if (view != null) {
			label = view.label;
			view.current = true;
		}

		last_view = view;
	}
}
