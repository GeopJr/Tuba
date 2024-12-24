public class Tuba.Views.TabbedBase : Views.Base {

	static int id_counter = 0;

	protected Adw.ViewSwitcher switcher;
	protected Adw.ViewSwitcherBar switcher_bar;
	protected Adw.ViewStack stack;
	protected Gtk.Stack title_stack;

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

		states.remove (scrolled);
		states.add_named (stack, "content");

		switcher_bar.stack = switcher.stack = stack;
	}

	~TabbedBase () {
		debug ("Destroying TabbedBase");

		foreach (var tab in views) {
			stack.remove (tab);
		}
		views = {};
	}

	#if !USE_LISTVIEW
		public override void unbind_listboxes () {
			foreach (var tab in views) {
				tab.unbind_listboxes ();
			}
			base.unbind_listboxes ();
		}
	#endif

	protected virtual bool title_stack_page_visible {
		get {
			return title_stack.visible_child_name == "title";
		}

		set {
			title_stack.visible_child_name = (value ? "title" : "switcher");
		}
	}

	public override void build_header () {
		title_stack = new Gtk.Stack () {
			hhomogeneous = false
		};
		header.title_widget = title_stack;

		switcher = new Adw.ViewSwitcher () { policy = Adw.ViewSwitcherPolicy.WIDE };
		title_stack.add_named (switcher, "switcher");

		switcher_bar = new Adw.ViewSwitcherBar ();
		toolbar_view.add_bottom_bar (switcher_bar);

		var title_header = new Adw.WindowTitle (label, "");
		bind_property ("label", title_header, "title", BindingFlags.SYNC_CREATE);
		title_stack.add_named (title_header, "title");

		title_stack_page_visible = false;
		var condition = new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			550, Adw.LengthUnit.SP
		);

		if (this.current_breakpoint != null) remove_breakpoint (this.current_breakpoint);
		this.small = true;
		var breakpoint = new Adw.Breakpoint (condition);
		breakpoint.add_setter (this, "title-stack-page-visible", true);
		breakpoint.add_setter (switcher_bar, "reveal", true);
		add_breakpoint (breakpoint);
	}

	public void add_tab (Views.Base view) {
		id_counter++;
		views += view;
		var page = stack.add_titled (view, id_counter.to_string (), view.label);
		view.bind_property ("icon", page, "icon-name", BindingFlags.SYNC_CREATE);
		view.bind_property ("needs-attention", page, "needs-attention", BindingFlags.SYNC_CREATE);
		view.bind_property ("badge-number", page, "badge-number", BindingFlags.SYNC_CREATE);
		view.header.hide ();
	}

	public Views.ContentBase add_list_tab (string label, string icon, string? empty_state_title = null) {
		var tab = new Views.ContentBase ();
		tab.label = label;
		tab.icon = icon;

		if (empty_state_title != null) tab.empty_state_title = empty_state_title;

		add_tab (tab);

		return tab;
	}

	public Views.ContentBase add_timeline_tab (string label, string icon, string url, Type accepts, string? empty_state_title = null, string? empty_state_icon = null) {
		var tab = new Views.Accounts () {
			url = url,
			label = label,
			icon = icon,
			accepts = accepts
		};
		tab.label = label;
		tab.icon = icon;

		if (empty_state_icon != null) tab.empty_timeline_icon = empty_state_icon;
		if (empty_state_title != null) tab.empty_state_title = empty_state_title;

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

	public override void on_content_changed () {
		foreach_tab (tab => {
			tab.on_content_changed ();
		});
		base_status = null;
	}

	public override void scroll_page (bool up = false) {
		var c_scrolled = stack.visible_child as Views.Base;
		if (c_scrolled != null)
			c_scrolled.scroll_page (up);
	}

	protected virtual void on_view_switched () {
		var view = stack.visible_child as Views.Base;

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
