public class Tootle.Desktop {

    // Open a URI in the user's default browser
    public static void open_url (string url) {
        Gtk.show_uri (null, url, Gdk.CURRENT_TIME);
    }

    // Copy a string to the clipboard
    public static void copy (string str) {
        var display = window.get_display ();
        var clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
        clipboard.set_text (RichLabel.restore_entities (str), -1);
    }

    // Download a file from the web to a user's configured Downloads folder
    public static void download_file (string url) {
        debug ("Downloading file: %s", url);
        
        var i = url.last_index_of ("/");
        var name = url.substring (i + 1, url.length - i - 1);
        if (name == null)
            name = "unknown";
        
        var dir_path = "%s/%s".printf (GLib.Environment.get_user_special_dir (UserDirectory.DOWNLOAD), app.program_name);
        var file_path = "%s/%s".printf (dir_path, name);
        
        var msg = new Soup.Message("GET", url);
        msg.finished.connect(() => {
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
                app.toast ("Media downloaded");
            } catch (Error e) {
                app.toast (e.message);
                warning ("Error: %s\n", e.message);
            }
        });
        network.queue (msg);
    }
    
}
