public class Tuba.Views.Main : Views.TabbedBase {
	construct {
        is_main = true;

		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Conversations ());
    }

	private Gtk.Button search_button;
	private Gtk.Button fake_back_button;
	private void update_fake_button (bool input = false) {
		fake_back_button.visible = stack.visible_child_name != "1" && input;
	}

	protected override void on_view_switched () {
		base.on_view_switched ();

		if (app.main_window != null) {
			update_fake_button (!app.main_window.is_mobile);
		}
	}

	private void go_home () {
		app.main_window.set_sidebar_selected_item (0);
		((Views.TabbedBase) app.main_window.main_page.child).change_page_to_named ("1");
	}

	private void bind () {
		app.main_window.bind_property ("is-mobile", search_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", switcher_bar, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", switcher, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", title_header, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.notify["is-mobile"].connect (() => {
			if (app.main_window.is_home) {
				update_fake_button (!app.main_window.is_mobile);

				if (app.main_window.is_mobile) {
					app.main_window.set_sidebar_selected_item (0);
				} else {
					switch (stack.visible_child_name) {
						case "1":
							app.main_window.set_sidebar_selected_item (0);
							break;
						case "2":
							app.main_window.set_sidebar_selected_item (1);
							break;
						case "3":
							app.main_window.set_sidebar_selected_item (2);
							break;
					}
				}
			}
		});
		update_fake_button (!app.main_window.is_mobile);
	}

	public override void build_header () {
		base.build_header ();

		search_button = new Gtk.Button () {
			icon_name = "tuba-loupe-large-symbolic",
			tooltip_text = _("Search")
		};
		search_button.clicked.connect (open_search);
		header.pack_end (search_button);

		fake_back_button = new Gtk.Button () {
			icon_name = "go-previous-symbolic",
			tooltip_text = _("Home")
		};
		fake_back_button.clicked.connect (go_home);
		header.pack_start (fake_back_button);

		ulong main_window_notify = 0;
		main_window_notify = app.notify["main-window"].connect (() => {
			bind ();

			app.disconnect (main_window_notify);
		});

		var sidebar_button = new Gtk.ToggleButton ();
		header.pack_start (sidebar_button);
		sidebar_button.icon_name = "tuba-dock-left-symbolic";

		app.notify["main-window"].connect (() => {
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
		});

	}

	void open_search () {
		app.main_window.open_view (new Views.Search ());
	}
}
