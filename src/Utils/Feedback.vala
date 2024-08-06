public class Tuba.Feedback {
	public static string sound_theme { get; private set; }

	static construct {
		var settings = new GLib.Settings ("org.gnome.desktop.sound");
		sound_theme = settings.get_string ("theme-name");
	}

	public static void trigger_event (string event_name, int timeout = -1) {
		if (!Lfb.is_initted () || timeout == 0) return;

		var event = new Lfb.Event (event_name) {
			timeout = timeout
		};
		event.trigger_feedback_async.begin (null, (obj, res) => {
			try {
				event.trigger_feedback_async.end (res);
			} catch (GLib.Error e) {
				warning (@"Error triggering $event_name: $(e.message)");
			}
		});
	}
}
