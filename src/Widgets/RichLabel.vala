using Gtk;

public class Tootle.RichLabel : Gtk.Label {

    public weak Mention[]? mentions;

    public RichLabel (string text) {
        set_label (text);
        set_use_markup (true);
        activate_link.connect (open_link);
    }

    public static string escape_entities (string content) {
        return content
               .replace ("&nbsp;", " ")
               .replace ("'", "&apos;");
    }

    public static string restore_entities (string content) {
        return content
               .replace ("&amp;", "&")
               .replace ("&lt;", "<")
               .replace ("&gt;", ">")
               .replace ("&apos;", "'")
               .replace ("&quot;", "\"");
    }

    public new void set_label (string text) {
        base.set_markup (Html.simplify(escape_entities (text)));
    }

    public void wrap_words () {
        halign = Gtk.Align.START;
        single_line_mode = false;
        set_line_wrap (true);
        wrap_mode = Pango.WrapMode.WORD_CHAR;
        justify = Gtk.Justification.LEFT;
        xalign = 0;
    }

    public bool open_link (string url){
        if (mentions != null){
            foreach (Mention mention in mentions) {
                if (url == mention.url){
                    AccountView.open_from_id (mention.id);
                    return true;
                }
            }
        }

        if ("/tags/" in url){
            var encoded = url.split("/tags/")[1];
            var hashtag = Soup.URI.decode (encoded);
            window.open_view (new HashtagView (hashtag));
            return true;
        }

        if ("/@" in url){
            var uri = new Soup.URI (url);
            var username = url.split("/@")[1];

            if ("/" in username)
                StatusView.open_from_link (url);
            else
                AccountView.open_from_name ("@" + username + "@" + uri.get_host ());

            return true;
        }

        Desktop.open_uri (url);
        return true;
    }

}
