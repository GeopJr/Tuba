[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/main.ui")]
public class Tuba.Dialogs.MainWindow: Adw.ApplicationWindow, Saveable {
	[GtkChild] unowned Adw.NavigationView navigation_view;
	[GtkChild] public unowned Adw.OverlaySplitView split_view;
	[GtkChild] unowned Views.Sidebar sidebar;
	//  [GtkChild] unowned Gtk.Stack main_stack;
	[GtkChild] unowned Views.MediaViewer media_viewer;
	[GtkChild] unowned Adw.Breakpoint breakpoint;
	[GtkChild] unowned Adw.ToastOverlay toast_overlay;

	public void set_sidebar_selected_item (int pos) {
		sidebar.set_sidebar_selected_item (pos);
	}

	Views.Base? last_view = null;

	construct {
		construct_saveable (settings);

		var gtk_settings = Gtk.Settings.get_default ();
		if (gtk_settings != null) gtk_settings.gtk_label_select_on_focus = false;

		breakpoint.add_setter (app, "is-mobile", true);
		app.notify["is-mobile"].connect (update_selected_home_item);
		media_viewer.bind_property ("visible", split_view, "can-focus", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		media_viewer.notify["visible"].connect (on_media_viewer_toggle);
		settings.notify["darken-images-on-dark-mode"].connect (settings_updated);

		app.toast.connect (add_toast);
		app.notify["is-online"].connect (on_network_change);
	}

	private void on_network_change () {
		if (app.is_online) {
			go_back_to_start ();
			app.refresh ();
		}
	}

	private void settings_updated () {
		Tuba.toggle_css (split_view, settings.darken_images_on_dark_mode, "ttl-darken-images");
	}

	private void add_toast (string content, uint timeout = 0) {
		toast_overlay.add_toast (new Adw.Toast (content) {
			timeout = timeout
		});
	}

	private weak Gtk.Widget? media_viewer_source_widget;
	private void on_media_viewer_toggle () {
		if (is_media_viewer_visible || media_viewer_source_widget == null) return;

		Gtk.Widget focusable_widget = media_viewer_source_widget;
		if (focusable_widget != null) focusable_widget.grab_focus ();
		media_viewer_source_widget = null;
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
		set_sidebar_selected_item (0);
		navigation_view.popped.connect (on_popped);
		main_page = new Adw.NavigationPage (new Views.Main (), _("Home"));
		navigation_view.add (main_page);

		#if !DEV_MODE
			if (Build.PROFILE == "development") {
				this.add_css_class ("devel");
			}
		#endif
	}

	public bool is_media_viewer_visible {
		get { return media_viewer.visible; }
	}

	public void scroll_media_viewer (int pos) {
		if (!is_media_viewer_visible) return;

		media_viewer.scroll_to (pos, false);
	}

	public void show_media_viewer (
		string url,
		Tuba.Attachment.MediaType media_type,
		Gdk.Paintable? preview,
		Gtk.Widget? source_widget = null,
		bool as_is = false,
		string? alt_text = null,
		string? user_friendly_url = null,
		bool stream = false,
		bool? load_and_scroll = null,
		bool reveal_media_viewer = true
	) {
		if (as_is && preview == null) return;

		media_viewer.add_media (url, media_type, preview, as_is, alt_text, user_friendly_url, stream, source_widget, load_and_scroll);

		if (reveal_media_viewer) {
			media_viewer_source_widget = app.main_window.get_focus ();
			media_viewer.reveal (source_widget);
		}
	}

	public void reveal_media_viewer_manually (Gtk.Widget? source_widget = null) {
		if (is_media_viewer_visible) return;

		media_viewer_source_widget = app.main_window.get_focus ();
		media_viewer.reveal (source_widget);
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

			var book_dialog = new Adw.Dialog () {
				title = book.title,
				child = toolbar_view,
				content_width = 460,
				content_height = 640
			};

			book_dialog.present (this);

			((Widgets.BookWyrmPage) book_widget).selectable = true;
		} catch {
			if (fallback != null) Host.open_url (fallback);
		}
	}

	public Views.Base open_view (Views.Base view) {
		if (
			(
				navigation_view != null
				&& navigation_view.visible_page != null
				&& navigation_view.visible_page.child == view
			)
			|| (
				last_view != null
				&& last_view.label == view.label
				&& !view.allow_nesting
				&& view.uid == last_view.uid
			)
		) return view;

		Adw.NavigationPage page = new Adw.NavigationPage (view, view.label);
		if (view.is_sidebar_item) {
			navigation_view.replace ({ main_page, page });
		} else {
			if (last_view != null) last_view.update_last_widget ();
			navigation_view.push (page);
		}

		return view;
	}

	public void on_popped () {
		var content_base = navigation_view.visible_page.child as Views.Base;
		if (content_base != null && content_base.last_widget != null) content_base.last_widget.grab_focus ();
	}

	public bool back () {
		if (is_media_viewer_visible) {
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
			if (app.is_mobile) {
				set_sidebar_selected_item (0);
			} else {
				var main_view = main_page.child as Views.Main;
				if (main_view == null) return;

				switch (main_view.visible_child_name) {
					case "1":
						set_sidebar_selected_item (0);
						break;
					case "2":
						set_sidebar_selected_item (1);
						break;
					case "3":
						set_sidebar_selected_item (2);
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
