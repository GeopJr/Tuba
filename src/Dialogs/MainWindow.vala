[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/main.ui")]
public class Tuba.Dialogs.MainWindow: Adw.ApplicationWindow, Saveable {
	[GtkChild] unowned Adw.NavigationView navigation_view;
	[GtkChild] public unowned Adw.OverlaySplitView split_view;
	[GtkChild] unowned Views.Sidebar sidebar;
	[GtkChild] unowned Gtk.Stack main_stack;
	[GtkChild] unowned Views.MediaViewer media_viewer;
	[GtkChild] unowned Adw.Breakpoint breakpoint;

	public bool is_mobile { get; set; default = false; }

	Views.Base? last_view = null;

	construct {
		construct_saveable (settings);

		var gtk_settings = Gtk.Settings.get_default ();
		breakpoint.add_setter (this, "is-mobile", true);
		notify["is-mobile"].connect (update_selected_home_item);
	}

	public bool is_home {
		get {
			return navigation_view.navigation_stack.get_n_items () == 1;
		}
	}

	public Adw.NavigationPage main_page;
	public MainWindow (Adw.Application app) {
		Object (
			application: app,
			icon_name: Build.DOMAIN,
			title: Build.NAME,
			resizable: true
		);
		sidebar.set_sidebar_selected_item (0);
		main_page = new Adw.NavigationPage (new Views.Main (), _("Home"));
		navigation_view.add (main_page);

		#if !DEV_MODE
			if (Build.PROFILE == "development") {
				this.add_css_class ("devel");
			}
		#endif
	}

	public bool is_media_viewer_visible () {
		return main_stack.visible_child_name == "media_viewer";
	}

	public void scroll_media_viewer (int pos) {
		if (!is_media_viewer_visible ()) return;

		media_viewer.scroll_to (pos);
	}

	public void show_media_viewer (string url, string? alt_text, bool video, Gdk.Paintable? preview, int? pos) {
		if (!is_media_viewer_visible ()) {
			main_stack.visible_child_name = "media_viewer";
			media_viewer.clear.connect (hide_media_viewer);
		}

		if (video) {
			media_viewer.add_video (url, preview, pos);
		} else {
			media_viewer.add_image (url, alt_text, preview, pos);
		}
	}

	public void show_media_viewer_single (string? url, Gdk.Paintable? paintable) {
		if (paintable == null) return;

		if (!is_media_viewer_visible ()) {
			main_stack.visible_child_name = "media_viewer";
			media_viewer.clear.connect (hide_media_viewer);
		}

		media_viewer.set_single_paintable (url, paintable);
	}

	public void show_media_viewer_remote_video (string url, Gdk.Paintable? preview, string? user_friendly_url = null) {
		if (!is_media_viewer_visible ()) {
			main_stack.visible_child_name = "media_viewer";
			media_viewer.clear.connect (hide_media_viewer);
		}

		media_viewer.set_remote_video (url, preview, user_friendly_url);
	}

	public void hide_media_viewer () {
		if (!is_media_viewer_visible ()) return;

		main_stack.visible_child_name = "main";
	}

	public void show_book (API.BookWyrm book, string? fallback = null) {
		try {
			var book_widget = book.to_widget ();
			var clamp = new Adw.Clamp () {
				child = book_widget,
				tightening_threshold = 100,
				valign = Gtk.Align.START
			};
			var scroller = new Gtk.ScrolledWindow () {
				hexpand = true,
				vexpand = true
			};
			scroller.child = clamp;

			var toolbar_view = new Adw.ToolbarView ();
			var headerbar = new Adw.HeaderBar ();

			toolbar_view.add_top_bar (headerbar);
			toolbar_view.set_content (scroller);

			var book_dialog = new Adw.Window () {
				modal = true,
				title = book.title,
				transient_for = this,
				content = toolbar_view,
				default_width = 460,
				default_height = 520
			};

			book_dialog.show ();

			((Widgets.BookWyrmPage) book_widget).selectable = true;
		} catch {
			if (fallback != null) Host.open_uri (fallback);
		}
	}

	public Views.Base open_view (Views.Base view) {
		if (
			navigation_view?.visible_page?.child == view
			|| (
				last_view != null
				&& last_view.label == view.label
				&& !view.allow_nesting
			)
		) return view;

		Adw.NavigationPage page = new Adw.NavigationPage (view, view.label);
		if (view.is_sidebar_item && navigation_view.visible_page != main_page) {
			navigation_view.replace ({ main_page, page });
		} else {
			navigation_view.push (page);
		}

		return view;
	}

	public bool back () {
		if (is_media_viewer_visible ()) {
			media_viewer.clear ();
			return true;
		};

		if (last_view == null) return true;

		navigation_view.pop ();
		return true;
	}

	public void go_back_to_start () {
		var navigated = true;
		while (navigated) {
			navigated = navigation_view.pop ();
		}
		((Views.TabbedBase) main_page.child).change_page_to_named ("1");
	}

	public void scroll_view_page (bool up = false) {
		var c_view = navigation_view.visible_page.child as Views.Base;
		if (c_view != null) {
			c_view.scroll_page (up);
		}
	}

	// public override bool delete_event (Gdk.EventAny event) {
	// 	window = null;
	// 	return app.on_window_closed ();
	// }

	//FIXME: switch timelines with 1-4. Should be moved to Views.TabbedBase
	public void switch_timeline (int32 num) {}

	public void update_selected_home_item () {
		if (is_home) {
			if (is_mobile) {
				sidebar.set_sidebar_selected_item (0);
			} else {
				var main_view = main_page.child as Views.Main;
				if (main_view == null) return;

				switch (main_view.visible_child_name) {
					case "1":
						sidebar.set_sidebar_selected_item (0);
						break;
					case "2":
						sidebar.set_sidebar_selected_item (1);
						break;
					case "3":
						sidebar.set_sidebar_selected_item (2);
						break;
				}
			}
		}
	}

	[GtkCallback]
	void on_visible_page_changed () {
		var view = navigation_view.visible_page.child as Views.Base;

		if (view.is_main)
			update_selected_home_item ();

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
}
