using Gtk;
using Gee;

public class Tootle.Widgets.RichLabel : Label {

	public weak ArrayList<API.Mention>? mentions;

	public string text {
		get {
			return this.label;
		}
		set {
			this.label = escape_entities (Html.simplify (value));
		}
	}

	construct {
		use_markup = true;
		xalign = 0;
		wrap_mode = Pango.WrapMode.WORD_CHAR;
		justify = Justification.LEFT;
		single_line_mode = false;
		set_line_wrap (true);
		activate_link.connect (open_link);
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

	public bool open_link (string url) {
		if ("tootle://" in url)
			return false;

		if (mentions != null){
			mentions.@foreach (mention => {
				if (url == mention.url)
					mention.open ();
				return true;
			});
		}

		if ("/tags/" in url) {
			var encoded = url.split ("/tags/")[1];
			var tag = Soup.URI.decode (encoded);
			window.open_view (new Views.Hashtag (tag));
			return true;
		}

		var resolve = "@" in url;
		var resolved = false;
		if (resolve) {
			accounts.active.resolve.begin (url, (obj, res) => {
				try {
					accounts.active.resolve.end (res).open ();
					resolved = true;
				}
				catch (Error e) {
					warning (@"Failed to resolve URL \"$url\":");
					warning (e.message);
				}
			});
		}

		if (!resolved)
			Desktop.open_uri (url);

		return true;
	}


}
