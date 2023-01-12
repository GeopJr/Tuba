using Gtk;
using Gdk;

[GtkTemplate (ui = "/dev/geopjr/tooth/ui/dialogs/main.ui")]
public class Tooth.Dialogs.MainWindow: Adw.ApplicationWindow, Saveable {

	public const string ZOOM_CLASS = "ttl-scalable";

	[GtkChild] public unowned Adw.Flap flap;
	[GtkChild] unowned Adw.Leaflet leaflet;
	[GtkChild] unowned Views.Sidebar sidebar;

	Views.Base? last_view = null;

	construct {
		construct_saveable (settings);

		var gtk_settings = Gtk.Settings.get_default ();
		//  settings.bind_property ("dark-theme", gtk_settings, "gtk-application-prefer-dark-theme", BindingFlags.SYNC_CREATE);
		settings.notify["post-text-size"].connect (() => on_zoom_level_changed ());

		on_zoom_level_changed ();
		// button_press_event.connect (on_button_press);
	}

	public MainWindow (Adw.Application app) {
		Object (
			application: app,
			icon_name: Build.DOMAIN,
			title: Build.NAME,
			resizable: true
		);
		sidebar.set_sidebar_selected_item(0);
		open_view (new Views.Main ());

		if (Build.PROFILE == "development") {
			this.add_css_class ("devel");
		}
	}

	public Views.Base open_view (Views.Base view) {
		if (last_view != null && last_view.label == view.label && !view.is_profile) return view;

		if (last_view != null && !last_view.is_main && view.is_sidebar_item) {
			leaflet.remove(last_view);
		}

		leaflet.append (view);
		leaflet.visible_child = view;
		return view;
	}

	public bool back () {
		if (last_view == null) return true;

		if (last_view.is_sidebar_item)
			sidebar.set_sidebar_selected_item(0);
		
		leaflet.navigate (Adw.NavigationDirection.BACK);
		return true;
	}

	public void go_back_to_start () {
		var navigated = true;
		while(navigated) {
			navigated = leaflet.navigate (Adw.NavigationDirection.BACK);
		}
	}

	// public override bool delete_event (Gdk.EventAny event) {
	// 	window = null;
	// 	return app.on_window_closed ();
	// }

	//FIXME: switch timelines with 1-4. Should be moved to Views.TabbedBase
	public void switch_timeline (int32 num) {}

	//FIXME: Handle back mouse button
	// bool on_button_press (EventButton ev) {
	// 	if (ev.button == 8)
	// 		return back ();
	// 	return false;
	// }

	void on_zoom_level_changed () {
		var scale = settings.post_text_size;
		var css = "";
		if (scale > 100) {
			css ="""
				.%s label {
					font-size: %i%;
				}
			""".printf (ZOOM_CLASS, scale);
		}
		// app.zoom_css_provider.load_from_data (css.data);
	}

	[GtkCallback]
	void on_view_changed () {
		var view = leaflet.visible_child as Views.Base;
		on_child_transition ();

		if (last_view != null) {
			last_view.current = false;
			last_view.on_hidden ();
		}

		if (view != null) {
			view.current = true;
			view.on_shown ();
		}

		last_view = view;
	}

	[GtkCallback]
	void on_child_transition () {
		if (leaflet.child_transition_running)
			return;

		Widget unused_child = null;
		while ((unused_child = leaflet.get_adjacent_child (Adw.NavigationDirection.FORWARD)) != null) {
			leaflet.remove (unused_child);
			unused_child.dispose ();
		}
	}

}
