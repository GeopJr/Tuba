using Gtk;
using Gee;

public class Tooth.Widgets.RichLabelContainer : Adw.Bin {

	Button widget;
	Box button_child;
	string on_click_url = null;
	public weak ArrayList<API.Mention>? mentions;

	construct {
		widget = new Button ();
		button_child = new Box(Orientation.HORIZONTAL, 0);

		widget.child = button_child;
		widget.halign = Align.START;

		child = widget;
		widget.clicked.connect (on_click);
	}

	public void set_label (string text, string? url, Gee.HashMap<string, string>? emojis, bool force_no_style = false, bool should_markup = false) {
		if (text.contains(":") && emojis != null) {
			string[] labelss = text.split (":");

			// Whether the last item was an emoji
			bool was_emoji = false;
			// Whether its the first item
			bool is_first = labelss[0].get_char() != ':';

			// The last created label
			Label? last_label = null; 
			foreach (unowned string str in labelss) {
				// If str is an available emoji
				if (emojis.has_key(str)) {
					button_child.append(new Widgets.Emoji(emojis.get(str)));
					was_emoji = true;
				} else {
					// The label
					// if the last item was not an emoji
					// and its not the first item, prefix
					// it with a ":"
					// This way if someone has a name that
					// includes ":" (and its not an emoji)
					// we re-create the original string
					string txt =  (!was_emoji && !is_first ? ":" : "") + str;
					// If the last label was not an emoji
					// append the new label to it
					// instead of creating a new one
					if (last_label != null && !was_emoji) {
						last_label.label = last_label.label + txt;
					} else {
						var tmp_child = new Label ("") {
							xalign = 0,
							wrap = true,
							wrap_mode = Pango.WrapMode.WORD_CHAR,
							justify = Justification.LEFT,
							single_line_mode = false,
							use_markup = false
						};
						tmp_child.label = txt;
						button_child.append(tmp_child);
					}
					was_emoji = false;
				}
				is_first = false;
			}
		} else {
			var tmp_child = new Label ("") {
				xalign = 0,
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				justify = Justification.LEFT,
				single_line_mode = false,
				use_markup = should_markup
			};
			tmp_child.label = text;
			button_child.append(tmp_child);
		}
		// if there's no url
		// make the button look
		// like a label
		if (url ==null || force_no_style) {
			widget.add_css_class("ttl-label-emoji-no-click");
		}

		on_click_url = url;
	}

	protected void on_click () {
		if (on_click_url == null) return;

		if (mentions != null){
			mentions.@foreach (mention => {
				if (on_click_url == mention.url)
					mention.open ();
				return true;
			});
		}

		if ("/tags/" in on_click_url) {
			var encoded = on_click_url.split ("/tags/")[1];
			var tag = Soup.URI.decode (encoded);
			app.main_window.open_view (new Views.Hashtag (tag));
			return;
		}

		if (should_resolve_url (on_click_url)) {
			accounts.active.resolve.begin (on_click_url, (obj, res) => {
				try {
					accounts.active.resolve.end (res).open ();
				}
				catch (Error e) {
					warning (@"Failed to resolve URL \"$on_click_url\":");
					warning (e.message);
					Host.open_uri (on_click_url);
				}
			});
		}
		else {
			Host.open_uri (on_click_url);
		}

		return;
	}	

	public static bool should_resolve_url (string url) {
		return settings.aggressive_resolving || "@" in url || "user" in url;
	}
}
