public class Tuba.AbstractCache : Object {
	protected static Gee.Map<string, GLib.Object> items_in_progress;

	static construct {
		items_in_progress = new Gee.HashMap<string, GLib.Object> ();
	}

	protected static string get_key (string id) {
		return id;
	}
}
