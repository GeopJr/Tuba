using Gtk;

public class Tooth.Views.Main : Views.TabbedBase {

	public Main () {
		Object(is_main: true);

		add_tab (new Views.Home ());
		add_tab (new Views.Notifications ());
		add_tab (new Views.Conversations ());
	}

	public override void build_header () {
		base.build_header ();
		back_button.hide ();

		var search_button = new Button();
		search_button.icon_name = "tooth-loupe-large-symbolic";
		search_button.tooltip_text = _("Search");
		search_button.clicked.connect ((source) => {
			app.main_window.open_view (new Views.Search ());
		});
		header.pack_end(search_button);

		var sidebar_button = new ToggleButton ();
		header.pack_start (sidebar_button);
		sidebar_button.icon_name = "tooth-dock-left-symbolic";

		app.notify["main-window"].connect (() => {
			if (app.main_window == null) {
				sidebar_button.hide ();
				return;
			}

			app.main_window.flap.bind_property ("folded", sidebar_button, "visible", BindingFlags.SYNC_CREATE);
			app.main_window.flap.bind_property ("reveal-flap", sidebar_button, "active", BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL);
			//  app.main_window.flap.bind_property ("reveal-flap", sidebar_button, "icon-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			//  	var state = src.get_boolean ();
			//  	target.set_string (state ? "sidebar-hide-symbolic" : "sidebar-show-symbolic" );
			//  	return true;
			//  });
		});

	}

}
