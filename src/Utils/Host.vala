public class Tuba.Host {

	// Open a URI in the user's default application
	public static bool open_url (string _uri) {
		var uri = _uri;
		if (!("://" in uri))
			uri = "file://" + _uri;

		if (settings.strip_tracking)
			uri = Tracking.strip_utm (uri);

		open_in_default_app (uri);
		return true;
	}

	// To avoid creating multiple Uri instances,
	// split opening into two wrappers, one for
	// strings and one for GLib.Uri
	public static bool open_uri (Uri uri) {
		string url;
		try {
			url = Tracking.strip_utm_from_uri (uri).to_string ();
		} catch (Error e) {
			warning (@"Error while stripping tracking params: $(e.message)");
			url = uri.to_string ();
		}
		open_in_default_app (url);

		return true;
	}

	private static void open_in_default_app (string uri) {
		debug (@"Opening URI: $uri");
		try {
			var success = AppInfo.launch_default_for_uri (uri, null);
			if (!success)
				throw new Oopsie.USER ("launch_default_for_uri() failed");
		} catch (Error e) {
			var launcher = new Gtk.UriLauncher (uri);
			launcher.launch.begin (app.active_window, null, (obj, res) => {
				try {
					launcher.launch.end (res);
				} catch (Error e) {
					warning (@"Error opening uri \"$uri\": $(e.message)");
				}
			});
		}
	}

	public static void copy (string str) {
		Gdk.Display display = Gdk.Display.get_default ();
		if (display == null) return;

		display.get_clipboard ().set_text (str);
	}

	public async static string download (string url) throws Error {
		debug (@"Downloading file: $url…");

		var file_name = Path.get_basename (url);
		var dir_name = Path.get_dirname (url);

		var dir_path = GLib.Path.build_path (GLib.Path.DIR_SEPARATOR_S, Tuba.cache_path, "manual", "media");
		var file_path = Path.build_path (
			Path.DIR_SEPARATOR_S,
			dir_path,
			str_hash (dir_name).to_string () + file_name);

		var dir = File.new_for_path (dir_path);
		if (!dir.query_exists ())
			dir.make_directory_with_parents ();

		var file = File.new_for_path (file_path);

		if (!file.query_exists ()) {
			// Disable libsoup's cache on these
			// it's better if we handle it so it doesn't affect its limits and loading
			var msg = yield new Request.GET (url).disable_cache ()
				.await ();

			var data = msg.response_body;
			FileOutputStream stream = yield file.create_async (FileCreateFlags.PRIVATE);
			yield stream.splice_async (data, OutputStreamSpliceFlags.CLOSE_SOURCE | OutputStreamSpliceFlags.CLOSE_TARGET);

			debug (@"   OK: File written to: $file_path");
		}
		else
			debug ("   OK: File already exists");

		return file_path;
	}

}
