public class Tootle.Html {

    public static string remove_tags (string content) {
        var all_tags = new Regex ("<(.|\n)*?>", RegexCompileFlags.CASELESS);
        return GLib.Markup.escape_text (all_tags.replace (content, -1, 0, ""));
    }

    public static string escape_pango_entities (string str) {
        return str
               .replace ("&nbsp;", " ")
               .replace ("'", "&apos;")
               .replace ("& ", "&amp;");
    }

    public static string restore_entities (string str) {
        return str
               .replace ("&amp;", "&")
               .replace ("&lt;", "<")
               .replace ("&gt;", ">")
               .replace ("&apos;", "'")
               .replace ("&quot;", "\"");
    }

    public static string simplify (string str) {
        var divided = str
        .replace("<br>", "\n")
        .replace("</br>", "")
        .replace("<br />", "\n")
        .replace("<p>", "")
        .replace("</p>", "\n\n");

        var html_params = new Regex ("(class|target|rel)=\"(.|\n)*?\"", RegexCompileFlags.CASELESS);
        var simplified = html_params.replace (divided, -1, 0, "");

        while (simplified.has_suffix ("\n"))
            simplified = simplified.slice (0, simplified.last_index_of ("\n"));

        return escape_pango_entities (simplified);
    }

    public static string uri_encode (string str) {
        var restored = restore_entities (str);
        return Soup.URI.encode (restored, ";&+");
    }

}
