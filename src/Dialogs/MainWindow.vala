using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/main.ui")]
public class Tootle.Dialogs.MainWindow: Hdy.Window, ISavedWindow {

	public const string ZOOM_CLASS = "app-scalable";

	[GtkChild]
	Hdy.Deck deck;

	Views.Base? last_view = null;

	construct {
		settings.bind_property ("dark-theme", Gtk.Settings.get_default (), "gtk-application-prefer-dark-theme", BindingFlags.SYNC_CREATE);
		settings.notify["post-text-size"].connect (() => on_zoom_level_changed ());

		on_zoom_level_changed ();
		deck.notify["visible-child"].connect (on_view_changed);
		button_press_event.connect (on_button_press);
		restore_state ();
	}

	public MainWindow (Gtk.Application app) {
		Object (
			application: app,
			icon_name: Build.DOMAIN,
			title: Build.NAME,
			resizable: true,
			window_position: WindowPosition.CENTER
		);
		open_view (new Views.Main ());
	}

	public Views.Base open_view (Views.Base view) {
		deck.add (view);
		deck.visible_child = view;
		return view;
	}

	public bool back () {
		var children = deck.get_children ();
		unowned var current = children.find (deck.visible_child);
		if (current != null) {
			unowned var prev = current.prev;
			if (current.prev != null) {
				deck.visible_child = prev.data;
				(current.data as Views.Base).unused = true;
				Timeout.add (deck.transition_duration, clean_unused_views);
			}
		}
		return true;
	}

	bool clean_unused_views () {
		deck.get_children ().foreach (c => {
			var view = c as Views.Base;
			if (view != null && view.unused)
				view.destroy ();
		});
		return Source.REMOVE;
	}

	public override bool delete_event (Gdk.EventAny event) {
		window = null;
		return app.on_window_closed ();
	}

	[Deprecated]
	public void switch_timeline (int32 num) {
	}

	bool on_button_press (EventButton ev) {
		if (ev.button == 8)
			return back ();
		return false;
	}

	void on_zoom_level_changed () {
		var css ="""
			.%s label {
				font-size: %i%;
			}
		""".printf (ZOOM_CLASS, settings.post_text_size);

		try {
			app.zoom_css_provider.load_from_data (css);
		}
		catch (Error e) {
			warning (@"Can't set zoom level: $(e.message)");
		}
	}

	void on_view_changed () {
		var view = deck.visible_child as Views.Base;

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
