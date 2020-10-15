using Gtk;

public class Tootle.Views.TabbedBase : Views.Base {

	static int ID_COUNTER = 0;

	protected Hdy.ViewSwitcherTitle switcher_title;
	protected Hdy.ViewSwitcherBar switcher_bar;
	protected Stack stack;

	Views.Base? last_view = null;

	construct {
		content = content_box;
		content_list.destroy ();
		state = "content";

		states.get_parent ().remove (states);
		view.get_style_context ().remove_class ("app-view");
		scrolled.destroy ();
		pack_start (states);

		stack = new Stack ();
		stack.transition_duration = 100;
		stack.transition_type = StackTransitionType.CROSSFADE;
		stack.notify["visible-child"].connect (on_view_switched);
		stack.show ();
		content_box.pack_start (stack);

		switcher_bar.stack = switcher_title.stack = stack;
	}

	public override void build_header () {
		switcher_title = new Hdy.ViewSwitcherTitle ();
		switcher_title.show ();
		header.bind_property ("title", switcher_title, "title", BindingFlags.SYNC_CREATE);
		header.bind_property ("subtitle", switcher_title, "subtitle", BindingFlags.SYNC_CREATE);
		header.custom_title = switcher_title;

		switcher_bar = new Hdy.ViewSwitcherBar ();
		switcher_bar.show ();
		switcher_title.bind_property ("title-visible", switcher_bar, "reveal", BindingFlags.SYNC_CREATE);
		pack_end (switcher_bar, false, false, 0);
	}

	public void add_tab (Views.Base view) {
		ID_COUNTER++;
		stack.add_titled (view, ID_COUNTER.to_string (), view.label);
		stack.child_set_property (view, "icon-name", view.icon);
		view.notify["needs-attention"].connect (() => {
			stack.child_set_property (view, "needs-attention", view.needs_attention);
		});
		view.header.hide ();
	}

	public Views.Base add_list_tab (string label, string icon) {
		var tab = new Views.Base ();
		tab.label = label;
		tab.icon = icon;

		add_tab (tab);

		return tab;
	}

	public delegate void TabCB (Views.Base tab);
	public void foreach_tab (TabCB cb) {
		stack.@foreach (child => {
			var tab = child as Views.Base;
			if (tab != null)
				cb (tab);
		});
	}

	public override void clear () {
		foreach_tab (tab => tab.clear ());
		on_content_changed ();
	}

	public override void on_content_changed () {
		var empty = true;
		foreach_tab (tab => {
			tab.visible = !tab.empty;
			if (tab.visible)
				empty = false;

			tab.on_content_changed ();
		});

		if (empty) {
			state = "status";
			status_message = STATUS_EMPTY;
		}
		else {
			state = "content";
		}
	}

	void on_view_switched () {
		var view = stack.visible_child as Views.Base;

		if (last_view != null) {
			last_view.current = false;
			last_view.on_hidden ();
		}

		if (view != null) {
			header.title = view.label;
			view.current = true;
			view.on_shown ();
		}

		last_view = view;
	}

}
