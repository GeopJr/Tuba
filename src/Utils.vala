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

    public static void copy (string str) {
        var display = Tootle.window.get_display ();
        var clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
        var normalized = str
            .replace ("&amp;", "&")
            .replace ("&apos;", "'");
        clipboard.set_text (normalized, -1);
    }

}
