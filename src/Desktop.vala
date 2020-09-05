using GLib;

public class Tootle.Desktop {

	// Open a URI in the user's default application
	public static bool open_uri (string uri) {
		message (@"Opening URI: $uri");
		try {
			Gtk.show_uri (null, uri, Gdk.CURRENT_TIME);
		}
		catch (Error e){
			try {
				string[] spawn_args = {"/usr/bin/xdg-open", uri};
				Process.spawn_sync (null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, null, null);
			}
			catch (Error e){
				warning (@"Can't open URI \"$uri\": $(e.message)");
				app.error (_("Open this URL in your browser:\n\n%s").printf (uri), "");
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
	public delegate void DownloadCallback (string path);
	public static void download (string url, owned DownloadCallback cb, owned Network.ErrorCallback ecb) {
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

		new Request.GET (url)
			.then ((sess, msg) => {
				try {
					var dir = File.new_for_path (dir_path);
					if (!dir.query_exists ())
						dir.make_directory ();

					var file = File.new_for_path (file_path);
					if (!file.query_exists ()) {
						var data = msg.response_body.data;
						FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
						stream.write (data);
					}
					message (@"OK: File written to: $file_path");
					cb (file_path);

				} catch (Error e) {
					warning ("Error: %s\n", e.message);
					ecb (0, e.message);
				}
			})
			.on_error ((owned) ecb)
			.exec ();
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
