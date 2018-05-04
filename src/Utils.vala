public class Tootle.Utils{

    public static void open_url (string url) {
        Gtk.show_uri (null, url, Gdk.CURRENT_TIME);
    }

    public static string escape_html (string content) {      
        var str = content
        .replace("<br>", "\n")
        .replace("</br>", "")
        .replace("<br />", "\n")
        .replace("rel=\"tag\"", "")
        .replace("rel=\"nofollow noopener\"", "")
        .replace("class=\"mention hashtag\"", "")
        .replace("class=\"mention\"", "")
        .replace("class=\"h-card\"", "")
        .replace("class=\"invisible\"", "")
        .replace("class=\"ellipsis\"", "")
        .replace("class=\"u-url mention\"", "")
        .replace("class=\"\"", "")
        .replace("<p>", "")
        .replace("</p>", "\n\n")
        .replace("target=\"_blank\"", "");
        
        while (str.has_suffix ("\n"))
            str = str.slice (0, str.last_index_of ("\n"));
        
        return str;
    }

}
