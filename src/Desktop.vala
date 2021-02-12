using GLib;

public class Tootle.Desktop {

	// Open a URI in the user's default application
	public static bool open_uri (string _uri) {
		var uri = _uri;
		if (!(":" in uri))
			uri = "file://" + _uri;

		message (@"Opening URI: $uri");
		try {
			var success = AppInfo.launch_default_for_uri (uri, null);
			if (!success)
				throw new Oopsie.USER (_("launch_default_for_uri() failed"));
		}
		catch (Error e){
			try {
				string[] spawn_args = {"/usr/bin/xdg-open", uri};
				Process.spawn_sync (null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, null, null);
			}
			catch (Error e){
				warning (@"xdg-open failed too: $(e.message)");
				app.inform (Gtk.MessageType.WARNING, _("Open this URL in your browser"), uri);
				return false;
			}
		}
		return true;
	}

	// Copy a string to the clipboard
	public static void copy (string str) {
		var display = window.get_display ();
		var clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
		clipboard.set_text (Widgets.RichLabel.restore_entities (str), -1);
	}

	public static string get_uri_host (string uri) {
		var p1 = uri;
		if ("//" in uri)
			p1 = uri.split ("//")[1];

		return p1.split ("/")[0];
	}

	// Download a file from the web to a user's configured Downloads folder
	public async static string download (string url) throws Error {
		message (@"Downloading file: $url...");

		var file_name = Path.get_basename (url);
		var dir_name = Path.get_dirname (url);

		var dir_path = Path.build_path (
			Path.DIR_SEPARATOR_S,
			Environment.get_user_special_dir (UserDirectory.DOWNLOAD),
			Build.NAME,
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

			message (@"OK: File written to: $file_path");
		}
		else
			message ("OK: File exists already");

		return file_path;
	}

	public static string fallback_icon (string normal, string fallback, string fallback2 = "broken") {
		var theme = Gtk.IconTheme.get_default ();
		if (theme.has_icon (normal))
			return normal;
		else
			return theme.has_icon (fallback) ? fallback : fallback2;
	}

	public static Gdk.Pixbuf icon_to_pixbuf (string name) {
		var theme = Gtk.IconTheme.get_default ();
		return theme.load_icon (name, 32, Gtk.IconLookupFlags.GENERIC_FALLBACK);
	}

}
