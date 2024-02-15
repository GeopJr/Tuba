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

		if ("/tags/" in url) {
			var from_url = Path.get_basename (url);
			var decoded = Uri.unescape_string (from_url) ?? from_url;
			var param_start = decoded.index_of_char ('?');
			if (param_start != -1)
				decoded = decoded.slice (0, param_start);
			app.main_window.open_view (new Views.Hashtag (decoded, null));
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
		} else {
			Host.open_uri (url);
		}

		return true;
	}

	public static bool should_resolve_url (string url) {
		return settings.aggressive_resolving || "@" in url || "user" in url;
	}
}
