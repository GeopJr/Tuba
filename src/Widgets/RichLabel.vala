public class Tuba.Widgets.RichLabel : Adw.Bin {
	Widgets.EmojiLabel widget;

	public weak Gee.ArrayList<API.Mention>? mentions;

	public string label {
		get { return widget.content; }
		set {
			widget.content = value;
			var rtl = rtl_regex.match (value);
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

	public bool use_markup {
		get { return widget.use_markup; }
		set { widget.use_markup = value; }
	}

	public bool selectable {
		get { return widget.selectable; }
		set { widget.selectable = value; }
	}

	public bool single_line_mode {
		get { return widget.single_line_mode; }
		set { widget.single_line_mode = value; }
	}

	public float xalign {
		get { return widget.xalign; }
		set { widget.xalign = value; }
	}

	public bool smaller_emoji_pixel_size {
		get { return widget.smaller_emoji_pixel_size; }
		set { widget.smaller_emoji_pixel_size = value; }
	}

	public bool large_emojis {
		get { return widget.large_emojis; }
		set { widget.large_emojis = value; }
	}

	public Gee.HashMap<string, string> instance_emojis {
		get { return widget.instance_emojis; }
		set { widget.instance_emojis = value; }
	}

	public int lines {
		get { return widget.lines; }
		set { widget.lines = value; }
	}

	// #756
	public bool fix_overflow_hack {
		get {
			return widget.fix_overflow_hack;
		}
		set {
			widget.fix_overflow_hack = value;
		}
	}

	public string get_text () {
		return widget.label_text;
	}

	public RichLabel (string? text = null) {
		if (text != null)
			label = text;
	}

	construct {
		widget = new Widgets.EmojiLabel () {
			use_markup = false,
			valign = Gtk.Align.CENTER
		};
		widget.activate_link.connect (on_activate_link);
		child = widget;
	}

	public bool on_activate_link (string url) {
		if (mentions != null) {
			bool found = false;
			mentions.@foreach (mention => {
				if (url == mention.url) {
					mention.open ();
					found = true;
					return false;
				}

				return true;
			});

			if (found) return true;
		}

		GLib.Uri? uri = null;
		try {
			uri = Uri.parse (url, UriFlags.NONE);

			// Hashtag urls are not resolvable.
			// Handle them manually if they end in /tags/<tag>.
			// Some backends might add query params, so using
			// GLib.Uri is preferred.
			if (Path.get_basename (Path.get_dirname (url)) == "tags") {
				app.main_window.open_view (
					new Views.Hashtag (
						Path.get_basename (uri.get_path ()),
						null
					)
				);
				return true;
			} else if (uri.get_scheme () == "web+ap") {
				app.handle_web_ap (uri);

				return true;
			}
		} catch (UriError e) {
			warning (@"Failed to parse \"$url\": $(e.message)");
		}

		if (should_resolve_url (url)) {
			accounts.active.resolve.begin (url, (obj, res) => {
				try {
					accounts.active.resolve.end (res).open ();
				} catch (Error e) {
					warning (@"Failed to resolve URL \"$url\":");
					warning (e.message);
					if (uri == null) {
						Host.open_url (url);
					} else {
						Host.open_uri (uri);
					}
				}
			});
		} else {
			if (uri == null) {
				Host.open_url (url);
			} else {
				Host.open_uri (uri);
			}
		}

		return true;
	}

	public static bool should_resolve_url (string url) {
		return settings.aggressive_resolving
			|| url.index_of_char ('@') != -1
			|| "/user" in url;
	}
}
