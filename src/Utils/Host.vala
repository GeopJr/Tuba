using GLib;
using Gdk;

public class Tuba.Host {

	// Open a URI in the user's default application
	public static bool open_uri (string _uri) {
		var uri = _uri;
		if (!(":" in uri))
			uri = "file://" + _uri;

		message (@"Opening URI: $uri");
		try {
			var success = AppInfo.launch_default_for_uri (uri, null);
			if (!success)
				throw new Oopsie.USER ("launch_default_for_uri() failed");
		}
		catch (Error e){
			Gtk.show_uri(app.active_window, uri, Gdk.CURRENT_TIME);
		}
		return true;
	}

	public static void copy (string str) {
		Display display = Display.get_default();
		if (display == null) return;

		display.get_clipboard().set_text(str);
	}

	public static string get_uri_host (string uri) {
		var p1 = uri;
		if ("//" in uri)
			p1 = uri.split ("//")[1];

		return p1.split ("/")[0];
	}

	public async static string download (string url) throws Error {
		message (@"Downloading file: $url...");

		var file_name = Path.get_basename (url);
		var dir_name = Path.get_dirname (url);

		var dir_path = Path.build_path (
			Path.DIR_SEPARATOR_S,
			Environment.get_user_cache_dir (), // Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
			Build.DOMAIN,
			get_uri_host (dir_name));

		var file_path = Path.build_path (
			Path.DIR_SEPARATOR_S,
			dir_path,
			str_hash (dir_name).to_string () + file_name);

		var dir = File.new_for_path (dir_path);
		if (!dir.query_exists ())
			dir.make_directory_with_parents ();

		var file = File.new_for_path (file_path);

		if (!file.query_exists ()) {
			var msg = yield new Request.GET (url)
				.await ();

			var data = msg.response_body.data;
			FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
			stream.write (data);

			message (@"   OK: File written to: $file_path");
		}
		else
			message ("   OK: File already exists");

		return file_path;
	}

}
