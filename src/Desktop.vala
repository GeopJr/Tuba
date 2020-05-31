public class Tootle.Desktop {

    // Open URI in the user's default application associated with it
    public static bool open_uri (string uri) {
        try {
            Gtk.show_uri (null, uri, Gdk.CURRENT_TIME);
        }
        catch (GLib.Error e){
            try {
              string[] spawn_args = {"/usr/bin/xdg-open", uri};
              Process.spawn_sync (null, spawn_args, null, SpawnFlags.SEARCH_PATH, null, null, null);
            }
            catch (GLib.Error e){
              warning ("Can't open %s: %s", uri, e.message);
              if (e.message == "Operation not supported") {
                  app.error (_("Open this in a web browser:\n\n"+uri),"");
              } else {
                  app.error (_("Error"), e.message);
              }
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

    // Download a file from the web to a user's configured Downloads folder
    public delegate void DownloadCallback (string path);
    public static void download (string url, DownloadCallback? cb = null, Network.ErrorCallback? ecb = null) {
        info (@"Downloading file: $url...");

        var i = url.last_index_of ("/");
        var name = url.substring (i + 1, url.length - i - 1);
        if (name == null)
            name = _("Unknown Attachment");

		var downloads = GLib.Environment.get_user_special_dir (UserDirectory.DOWNLOAD);
		var dir_path = @"$downloads/$(Build.NAME)";
        var file_path = @"$dir_path/$name";

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
                    info ("OK");
                    cb (file_path);

                } catch (Error e) {
                    warning ("Error: %s\n", e.message);
                    ecb (0, e.message);
                }
            })
            .on_error ((code, reason) => ecb)
            .exec ();
    }

    public static string fallback_icon (string normal, string fallback, string fallback2 = "broken") {
        var theme = Gtk.IconTheme.get_default ();
        if (theme.has_icon (normal))
        	return normal;
        else
        	return theme.has_icon (fallback) ? fallback : fallback2;
    }

    public static void set_hotkey_tooltip (Gtk.Widget widget, string? description, string[] accelerators) {
    	widget.tooltip_markup = Granite.markup_accel_tooltip (accelerators, description);
    }

}
