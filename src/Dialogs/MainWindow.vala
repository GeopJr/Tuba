using Gtk;
using Gdk;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/main.ui")]
public class Tuba.Dialogs.MainWindow: Adw.ApplicationWindow, Saveable {
	public const string ZOOM_CLASS = "ttl-scalable";

	[GtkChild] public unowned Adw.Flap flap;
	[GtkChild] unowned Adw.Leaflet leaflet;
	[GtkChild] unowned Views.Sidebar sidebar;
	[GtkChild] unowned Stack main_stack;
	[GtkChild] unowned Views.MediaViewer media_viewer;

	Views.Base? last_view = null;

	construct {
		construct_saveable (settings);

		var gtk_settings = Gtk.Settings.get_default ();
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

	public bool is_media_viewer_visible() {
		return main_stack.visible_child_name == "media_viewer"; 
	}

	public void scroll_media_viewer (int pos) {
		if (!is_media_viewer_visible()) return;

		media_viewer.scroll_to (pos);
	}

	public void show_media_viewer(string url, string? alt_text, bool video, Paintable? preview, int? pos) {
		if (!is_media_viewer_visible()) {
			main_stack.visible_child_name = "media_viewer";
			media_viewer.clear.connect(hide_media_viewer);
		}

		if (video) {
			media_viewer.add_video(url, preview, pos);
		} else {
			media_viewer.add_image(url, alt_text, preview, pos);
		}
	}

	public void show_media_viewer_single (string? url, Paintable? paintable) {
		if (paintable == null) return;

		if (!is_media_viewer_visible()) {
			main_stack.visible_child_name = "media_viewer";
			media_viewer.clear.connect(hide_media_viewer);
		}

		media_viewer.set_single_paintable (url, paintable);
	}

	public void show_media_viewer_remote_video(string url, Paintable? preview, string? user_friendly_url = null) {
		if (!is_media_viewer_visible()) {
			main_stack.visible_child_name = "media_viewer";
			media_viewer.clear.connect(hide_media_viewer);
		}

		media_viewer.set_remote_video (url, preview, user_friendly_url);
	}

	public void hide_media_viewer() {
		if (!is_media_viewer_visible()) return;

		main_stack.visible_child_name = "main";
	}

	public Views.Base open_view (Views.Base view) {
		if ((leaflet.visible_child == view) || (last_view != null && last_view.label == view.label && !view.is_profile)) return view;

		if (last_view != null && !last_view.is_main && view.is_sidebar_item) {
			leaflet.remove(last_view);
		}

		leaflet.append (view);
		leaflet.visible_child = view;
		return view;
	}

	public bool back () {
		if (is_media_viewer_visible()) {
			media_viewer.clear();
			return true;
		};

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
