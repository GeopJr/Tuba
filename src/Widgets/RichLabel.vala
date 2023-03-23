using Gtk;
using Gee;

public class Tuba.Widgets.RichLabel : Adw.Bin {

	Label widget;

	// TODO: We can parse <a> tags and extract resolvable URIs now
	public weak ArrayList<API.Mention>? mentions;

	public string label {
		get { return widget.label; }
		set { widget.label = value; }
	}

	public bool wrap {
		get { return widget.wrap; }
		set { widget.wrap = value; }
	}

	public bool selectable {
		get { return widget.selectable; }
		set { widget.selectable = value; }
	}

	public Pango.EllipsizeMode ellipsize {
		get { return widget.ellipsize; }
		set { widget.ellipsize = value; }
	}

	public bool single_line_mode {
		get { return widget.single_line_mode; }
		set { widget.single_line_mode = value; }
	}

	public float xalign {
	    get { return widget.xalign; }
	    set { widget.xalign = value; }
	}

	construct {
		widget = new Label ("") {
			xalign = 0,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			justify = Justification.LEFT,
			single_line_mode = false,
			use_markup = true
		};
		widget.activate_link.connect (on_activate_link);
		child = widget;
	}

	public RichLabel (string text) {
		widget.set_label (text);
		var rtl = rtl_regex.match(text);
		if (rtl) {
			xalign = is_rtl ? 0 : 1;
		} else {
			xalign = is_rtl ? 1 : 0;
		}
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

	bool on_activate_link (string url) {
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
			app.main_window.open_view (new Views.Hashtag (tag, null));
			return true;
		}

		if (should_resolve_url (url)) {
			accounts.active.resolve.begin (url, (obj, res) => {
				try {
					accounts.active.resolve.end (res).open ();
				}
				catch (Error e) {
					warning (@"Failed to resolve URL \"$url\":");
					warning (e.message);
					Host.open_uri (url);
				}
			});
		}
		else {
			Host.open_uri (url);
		}

		return true;
	}

	public static bool should_resolve_url (string url) {
		return settings.aggressive_resolving || "@" in url || "user" in url;
	}

}
