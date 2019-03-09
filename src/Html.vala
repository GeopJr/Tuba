public class Tootle.Html {

    public static string remove_tags (string content) {
        var all_tags = new Regex("<(.|\n)*?>", RegexCompileFlags.CASELESS);
        return all_tags.replace(content, -1, 0, "");
    }

    public static string simplify (string content) {
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

    public static string uri_encode (string content) {
        var to_escape = ";&+";
        return Soup.URI.encode (content, to_escape);
    }

}
