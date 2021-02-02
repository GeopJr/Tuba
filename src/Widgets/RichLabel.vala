using Gtk;
using Gee;

public class Tootle.Widgets.RichLabel : Label {

	// TODO: We can parse <a> tags and extract resolvable URIs now
	public weak ArrayList<API.Mention>? mentions;

	MarkupPolicy _markup = DISALLOW;
	public MarkupPolicy markup {
		get {
			return _markup;
		}
		set {
			_markup = value;
			_markup.apply (this);
		}
	}

	public string text {
		get {
			return this.label;
		}
		set {
			this.label = markup.process (value);
		}
	}

	construct {
		xalign = 0;
		wrap_mode = Pango.WrapMode.WORD_CHAR;
		justify = Justification.LEFT;
		single_line_mode = false;
		set_line_wrap (true);
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

	public override bool activate_link (string url) {
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

		var resolve = settings.aggressive_resolving || ("@" in url);
		if (!resolve)
			Desktop.open_uri (url);
		else {
			accounts.active.resolve.begin (url, (obj, res) => {
				try {
					accounts.active.resolve.end (res).open ();
				}
				catch (Error e) {
					warning (@"Failed to resolve URL \"$url\":");
					warning (e.message);
					Desktop.open_uri (url);
				}
			});
		}
		return true;
	}


}
