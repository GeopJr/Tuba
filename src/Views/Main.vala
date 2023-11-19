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

	protected override bool title_stack_page_visible {
		get {
			return title_stack.visible_child_name == "title";
		}

		set {
			title_stack.visible_child_name = app.main_window.is_mobile && value ? "switcher" : "title";
		}
	}

	private void bind () {
		app.main_window.bind_property ("is-mobile", search_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", switcher_bar, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", switcher, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", this, "title-stack-page-visible", GLib.BindingFlags.SYNC_CREATE);
	}

	public override void build_header () {
		base.build_header ();

		search_button = new Gtk.Button () {
			icon_name = "tuba-loupe-large-symbolic",
			tooltip_text = _("Search")
		};
		search_button.clicked.connect (open_search);
		header.pack_end (search_button);

		var sidebar_button = new Gtk.ToggleButton ();
		header.pack_start (sidebar_button);
		sidebar_button.icon_name = "tuba-dock-left-symbolic";

		ulong main_window_notify = 0;
		main_window_notify = app.notify["main-window"].connect (() => {
			if (app.main_window == null) {
				sidebar_button.hide ();
				return;
			}

			bind ();
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
