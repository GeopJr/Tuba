using Gtk;

public interface Tootle.Dialogs.ISavedWindow : Window {

	public void restore_state () {
		var settings = new Settings ();
		configure_window (settings);
		configure_event.connect ((ev) => on_configure (ev, settings));
	}

	public bool on_configure (Gdk.EventConfigure event, Settings settings) {
		int x, y, w, h;
		get_position (out x, out y);
		get_size (out w, out h);

		settings.window_x = x;
		settings.window_y = y;
		settings.window_w = w;
		settings.window_h = h;
		return false;
	}

	public void configure_window (Settings settings) {
		var x = settings.window_x;
		var y = settings.window_y;
		var w = settings.window_w;
		var h = settings.window_h;

		if (x + y > 0)
			this.move (x, y);

		if (h + w > 0) {
			this.default_width = w;
			this.default_height = h;
		}
	}

}
