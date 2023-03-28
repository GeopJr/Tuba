using Gtk;
using Gee;

public class Tuba.Widgets.RichLabelContainerTemp : Adw.Bin {
	Button widget;
	Widgets.EmojiLabelTemp button_child;
	string on_click_url = null;
	public weak ArrayList<API.Mention>? mentions;

	private bool _dim = false;
	public bool dim {
		get { return _dim; }
		set {
			_dim = value;
			if (value) {
				button_child.add_css_class("dim-label");
			} else {
				button_child.remove_css_class("dim-label");
			}
		}
	}

	private bool _small_font = false;
	public bool small_font {
		get { return _small_font; }
		set {
			_small_font = value;
			if (value) {
				button_child.add_css_class("ttl-status-heading");
				widget.add_css_class("ttl-status-heading-padding");
			} else {
				button_child.remove_css_class("ttl-status-heading");
				widget.add_css_class("ttl-status-heading-padding");
			}
		}
	}

	construct {
		widget = new Button () {
			css_classes = {"ttl-label-emoji-no-click", "flat"}
		};
		
		//  widget.halign = Align.START;

		child = widget;
		widget.clicked.connect (on_click);
	}

	public void set_label (string text, string? url, Gee.HashMap<string, string>? emojis, bool force_no_style = false, bool should_markup = false) {
		button_child = new Widgets.EmojiLabelTemp();

		widget.child = button_child;
		if (emojis != null)
			button_child.instance_emojis = emojis;
		if (text != null)
			button_child.content = text;

		// if there's url
		// make the button look
		// like a button
		if (url != null && !force_no_style) {
			widget.remove_css_class("ttl-label-emoji-no-click");
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
			app.main_window.open_view (new Views.Hashtag (tag, null));
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
