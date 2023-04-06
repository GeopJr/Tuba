using Gtk;
using Gee;

public class Tuba.Widgets.RichLabel : Adw.Bin {

	Widgets.EmojiLabelTemp widget;

	// TODO: We can parse <a> tags and extract resolvable URIs now
	public weak ArrayList<API.Mention>? mentions;

	public string label {
		get { return widget.content; }
		set {
			widget.content = value;
			var rtl = rtl_regex.match(value);
			if (rtl) {
				xalign = is_rtl ? 0 : 1;
			} else {
				xalign = is_rtl ? 1 : 0;
			}
		}
	}

	//  public bool wrap {
	//  	get { return widget.wrap; }
	//  	set { widget.wrap = value; }
	//  }

	public bool selectable {
		get { return widget.selectable; }
		set { widget.selectable = value; }
	}

	public bool ellipsize {
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

	public Gee.HashMap<string, string> instance_emojis {
		get { return widget.instance_emojis; }
		set { widget.instance_emojis = value; }
	}

	public RichLabel (string? text = null) {
		if (text != null)
			label = text;

		widget.lines = 100;
	}

	construct {
		widget = new Widgets.EmojiLabelTemp() {
			use_markup = true
		};
		widget.activate_link.connect (on_activate_link);
		child = widget;
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

	public bool on_activate_link (string url) {
		if (mentions != null){
			mentions.@foreach (mention => {
				if (url == mention.url)
					mention.open ();
				return true;
			});
		}

		if ("/tags/" in url) {
			var encoded = url.split ("/tags/")[1];
			var tag = Uri.unescape_string (encoded);
			app.main_window.open_view (new Views.Hashtag (tag ?? encoded, null));
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
