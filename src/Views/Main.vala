public class Tuba.Views.Main : Views.TabbedBase {
	construct {
        is_main = true;

		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Conversations ());
    }

	public string visible_child_name {
		get {
			return stack.visible_child_name;
		}
	}

	private Gtk.Button search_button;
	protected override void on_view_switched () {
		base.on_view_switched ();
	}

	// Unused
	//  private void go_home () {
	//  	((Views.TabbedBase) app.main_window.main_page.child).change_page_to_named ("1");
	//  	app.main_window.update_selected_home_item ();
	//  }

	private Gtk.Stack title_wrapper_stack;
	public bool title_wrapper_stack_visible {
		get {
			return title_wrapper_stack.visible_child_name == "title";
		}
		set {
			title_wrapper_stack.visible_child_name = (value ? "stack" : "title");
		}
	}

	private void bind () {
		app.bind_property ("is-mobile", search_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.bind_property ("is-mobile", switcher_bar, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.bind_property ("is-mobile", this, "title-wrapper-stack-visible", GLib.BindingFlags.SYNC_CREATE);
	}

	public override void build_header () {
		base.build_header ();
		header.title_widget = null;

		title_wrapper_stack = new Gtk.Stack ();
		title_wrapper_stack.add_named (title_stack, "stack");
		var title_header = new Adw.WindowTitle (label, "");
		bind_property ("label", title_header, "title", BindingFlags.SYNC_CREATE);
		title_wrapper_stack.add_named (title_header, "title");
		header.title_widget = title_wrapper_stack;

		search_button = new Gtk.Button () {
			icon_name = "tuba-loupe-large-symbolic",
			tooltip_text = _("Search")
		};
		search_button.clicked.connect (open_search);
		header.pack_end (search_button);

		var sidebar_button = new Gtk.ToggleButton ();
		header.pack_start (sidebar_button);
		sidebar_button.icon_name = "tuba-dock-left-symbolic";

		bind ();
		ulong main_window_notify = 0;
		main_window_notify = app.notify["main-window"].connect (() => {
			if (app.main_window == null) {
				sidebar_button.hide ();
				return;
			}

			app.main_window.split_view.bind_property (
				"collapsed",
				sidebar_button,
				"visible",
				BindingFlags.SYNC_CREATE
			);

			app.main_window.split_view.bind_property (
				"show-sidebar",
				sidebar_button,
				"active",
				BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
			);

			app.disconnect (main_window_notify);
		});

	}

	void open_search () {
		app.main_window.open_view (new Views.Search ());
	}
}
