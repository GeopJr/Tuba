public class Tuba.Views.Main : Views.TabbedBase {
	construct {
        is_main = true;

		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Conversations ());
    }

	public override void build_header () {
		base.build_header ();

		var search_button = new Gtk.Button ();
		search_button.icon_name = "tuba-loupe-large-symbolic";
		search_button.tooltip_text = _("Search");
		search_button.clicked.connect (open_search);
		header.pack_end (search_button);

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
