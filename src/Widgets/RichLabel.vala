using Gtk;
using Gee;

public class Tootle.Widgets.RichLabel : Label {

    public weak ArrayList<API.Mention>? mentions;

	construct {
		use_markup = true;
		xalign = 0;
        wrap_mode = Pango.WrapMode.WORD_CHAR;
        justify = Justification.LEFT;
        single_line_mode = false;
        set_line_wrap (true);
		activate_link.connect (open_link);
		get_style_context ().add_class (Dialogs.MainWindow.ZOOM_CLASS);
	}

    public RichLabel (string text) {
        set_label (text);
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

    public bool open_link (string url) {
        if ("tootle://" in url)
            return false;

        if (mentions != null){
            mentions.@foreach (mention => {
                if (url == mention.url)
                    Views.Profile.open_from_id (mention.id);
                return true;
            });
        }

        if ("/tags/" in url) {
            var encoded = url.split("/tags/")[1];
            var hashtag = Soup.URI.decode (encoded);
            window.open_view (new Views.Hashtag (hashtag));
            return true;
        }

        if ("@" in url || "tags" in url) {
            new Request.GET ("/api/v2/search")
                .with_account (accounts.active)
                .with_param ("resolve", "true")
                .with_param ("q", Soup.URI.encode (url, null))
                .then ((sess, mess) => {
                    var root = network.parse (mess);
                    var accounts = root.get_array_member ("accounts");
                    var statuses = root.get_array_member ("statuses");
                    var hashtags = root.get_array_member ("hashtags");

                    if (accounts.get_length () > 0) {
                        var item = accounts.get_object_element (0);
                        var obj = new API.Account (item);
                        window.open_view (new Views.Profile (obj));
                    }
                    else if (statuses.get_length () > 0) {
                        var item = accounts.get_object_element (0);
                        var obj = new API.Status (item);
                        window.open_view (new Views.ExpandedStatus (obj));
                    }
                    else if (hashtags.get_length () > 0) {
                        var item = accounts.get_object_element (0);
                        var obj = new API.Tag (item);
                        window.open_view (new Views.Hashtag (obj.name));
                    }
                    else {
                        Desktop.open_uri (url);
                    }
                })
                .on_error ((status, reason) => open_link_fallback (url, reason))
                .exec ();
        }
        else {
            Desktop.open_uri (url);
        }
        return true;
    }

    public bool open_link_fallback (string url, string reason) {
        warning (@"Can't resolve url: $url");
        warning (@"Reason: $reason");
        Desktop.open_uri (url);
        return true;
    }

}
