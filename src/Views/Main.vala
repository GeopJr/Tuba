public class Tuba.Views.Main : Views.TabbedBase {

	public Main () {
		Object (is_main: true);

		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Conversations ());
	}

	public override void build_header () {
		base.build_header ();
		back_button.hide ();

		var search_button = new Gtk.Button ();
		search_button.icon_name = "tuba-loupe-large-symbolic";
		search_button.tooltip_text = _("Search");
		search_button.clicked.connect (open_search);
		header.pack_end (search_button);

		var sidebar_button = new Gtk.ToggleButton ();
		header.pack_start (sidebar_button);
		sidebar_button.icon_name = "tuba-dock-left-symbolic";

		header.show_start_title_buttons = false;
		app.notify["main-window"].connect (() => {
			if (app.main_window == null) {
				sidebar_button.hide ();
				return;
			}

			app.main_window.flap.bind_property (
				"folded",
				sidebar_button,
				"visible",
				BindingFlags.SYNC_CREATE,
				(b, src, ref target) => {
					var state = src.get_boolean ();
					target.set_boolean (state);

					var sidebar = app.main_window.flap.flap as Views.Sidebar;
					if (sidebar != null) sidebar.show_window_controls = !state;
					header.show_start_title_buttons = state;

					return true;
				}
			);

			app.main_window.flap.bind_property (
				"reveal-flap",
				sidebar_button,
				"active",
				BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
			);
			//  app.main_window.flap.bind_property ("reveal-flap", sidebar_button, "icon-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			//  	var state = src.get_boolean ();
			//  	target.set_string (state ? "sidebar-hide-symbolic" : "sidebar-show-symbolic" );
			//  	return true;
			//  });
		});

	}

	void open_search () {
		app.main_window.open_view (new Views.Search ());
	}
}
