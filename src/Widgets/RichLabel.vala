public class Tuba.Widgets.RichLabel : Adw.Bin {
	Widgets.EmojiLabel widget;

	public Gee.ArrayList<API.Mention>? mentions;

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

	//  public bool focusable_label {
	//  	get { return widget.focusable; }
	//  	set {
	//  		this.focusable = value;
	//  		widget.focusable = value;
	//  	}
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

	public float yalign {
		get { return widget.yalign; }
		set { widget.yalign = value; }
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

	public string accessible_text {
		get { return widget.accessible_text; }
	}

	public string get_text () {
		return widget.label_text;
	}

	public RichLabel (string? text = null) {
		if (text != null)
			this.label = text;
	}

	public RichLabel.with_emojis (string? text = null, Gee.HashMap<string, string>? instance_emojis = null) {
		if (instance_emojis != null) this.instance_emojis = instance_emojis;
		if (text != null) this.label = text;
	}

	static construct {
		set_accessible_role (Gtk.AccessibleRole.LABEL);
	}

	construct {
		widget = new Widgets.EmojiLabel () {
			use_markup = false,
			valign = Gtk.Align.CENTER
		};
		widget.activate_link.connect (on_activate_link);
		child = widget;

		this.update_relation (Gtk.AccessibleRelation.LABELLED_BY, widget, null, -1);
		this.update_relation (Gtk.AccessibleRelation.DESCRIBED_BY, widget, null, -1);

		#if WEBKIT
			Gtk.GestureClick middle_click_gesture = new Gtk.GestureClick () {
				button = Gdk.BUTTON_MIDDLE
			};
			middle_click_gesture.pressed.connect (on_middle_clicked);
			this.add_controller (middle_click_gesture);
		#endif
	}

	public bool on_activate_link (string url) {
		widget.grab_focus ();

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
					open_in_browser (url, uri);
				}
			});
		} else {
			open_in_browser (url, uri);
		}

		return true;
	}

	private void open_in_browser (string url, GLib.Uri? uri = null) {
		#if WEBKIT
			if (settings.use_in_app_browser_if_available) {
				if (
					(uri != null && Views.Browser.can_handle_uri (uri))
					|| Views.Browser.can_handle_url (url)
				) {
					(new Views.Browser.with_url (url)).present (app.main_window);
					return;
				}
			}
		#endif
		if (uri == null) {
			Utils.Host.open_url.begin (url);
		} else {
			Utils.Host.open_uri.begin (uri);
		}
	}

	public static bool should_resolve_url (string url) {
		return settings.aggressive_resolving
			|| url.index_of_char ('@') != -1
			|| "/user" in url;
	}

	#if WEBKIT
		private void on_middle_clicked (int n_press, double x, double y) {
			if (n_press > 1 || !settings.use_in_app_browser_if_available) return;

			string? current_uri = widget.get_current_uri ();
			if (current_uri == null) return;

			Utils.Host.open_url.begin (current_uri);
		}
	#endif
}
