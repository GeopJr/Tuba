public class Tootle.Utils{

    public static void open_url (string url) {
        Gtk.show_uri (null, url, Gdk.CURRENT_TIME);
    }

    public static string escape_html (string content) {
        var all_tags = new Regex("<(.|\n)*?>", RegexCompileFlags.CASELESS);
        return all_tags.replace(content, -1, 0, "");
    }

    public static string simplify_html (string content) {      
        var divided = content
        .replace("<br>", "\n")
        .replace("</br>", "")
        .replace("<br />", "\n")
        .replace("<p>", "")
        .replace("</p>", "\n\n");
        
        var html_params = new Regex("(class|target|rel)=\"(.|\n)*?\"", RegexCompileFlags.CASELESS);
        var simplified = html_params.replace(divided, -1, 0, "");
        
        while (simplified.has_suffix ("\n"))
            simplified = simplified.slice (0, simplified.last_index_of ("\n"));
        
        return simplified;
    }
    
    public static string escape_entities (string content) {
        return content
            .replace ("&", "&amp;")
            .replace ("'", "&apos;");
    }
    
    public static string encode (string content) {
        var to_escape = ";&";
        return Soup.URI.encode (content, to_escape);
    }

    public static void copy (string str) {
        var display = Tootle.window.get_display ();
        var clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
        var normalized = str
            .replace ("&amp;", "&")
            .replace ("&apos;", "'");
        clipboard.set_text (normalized, -1);
    }
    
    public static void download (string url) {
        debug ("Downloading file: %s", url);
        
        var i = url.last_index_of ("/");
        var name = url.substring (i + 1, url.length - i - 1);
        if (name == null)
            name = "unknown";
        
        var dir_path = "%s/%s".printf (GLib.Environment.get_user_special_dir (UserDirectory.DOWNLOAD), Tootle.app.program_name);
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
                Tootle.app.toast ("Media downloaded");
            } catch (Error e) {
                Tootle.app.toast (e.message);
                warning ("Error: %s\n", e.message);
            }
        });
        Tootle.network.queue (msg);
    }

}
