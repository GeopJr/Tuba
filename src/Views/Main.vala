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

	private bool toolbar_view_mobile_style {
		set {
			toolbar_view.bottom_bar_style = toolbar_view.top_bar_style = value ? Adw.ToolbarStyle.RAISED : Adw.ToolbarStyle.FLAT;
		}
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
		((Views.TabbedBase) app.main_window.main_page.child).change_page_to_named ("1");
		app.main_window.update_selected_home_item ();
	}

	private void bind () {
		app.main_window.bind_property ("is-mobile", search_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", switcher_bar, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", switcher, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.bind_property ("is-mobile", title_header, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.main_window.notify["is-mobile"].connect (notify_bind);
		notify_bind ();
	}

	private void notify_bind () {
		update_fake_button (!app.main_window.is_mobile);
		toolbar_view_mobile_style = app.main_window.is_mobile;
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
