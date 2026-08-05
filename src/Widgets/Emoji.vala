public class Tuba.Widgets.Emoji : Adw.Bin {
	protected Gtk.Image image;
	public int pixel_size {
		get { return image.pixel_size; }
		set { image.pixel_size = value; }
	}
	public Gtk.IconSize icon_size {
		get { return image.icon_size; }
		set { image.icon_size = value; }
	}

	static construct {
		set_accessible_role (Gtk.AccessibleRole.IMG);
	}

	~Emoji () {
		if (cancellable != null) cancellable.cancel ();
		image.paintable = null;
	}

	private string? _shortcode = null;
	public string? shortcode {
		get { return _shortcode; }
		set {
			if (value != _shortcode) {
				_shortcode = value;
				this.tooltip_text = value == null ? "" : value;
			}
		}
	}

	GLib.Cancellable? cancellable = null;
	private string _emoji_url = "";
	public string emoji_url {
		get { return _emoji_url; }
		set {
			if (_emoji_url != value) {
				if (cancellable != null) cancellable.cancel ();
				if (value == null || value == "") {
					_emoji_url = "";
					image.paintable = null;
				} else {
					_emoji_url = value;
					var cached_paintable = Tuba.Helper.Image.lookup_cache (emoji_url);
					if (cached_paintable == null) {
						cancellable = new GLib.Cancellable ();
						Tuba.Helper.Image.request_paintable (emoji_url, null, false, on_cache_response, cancellable);
					} else {
						on_cache_response (cached_paintable);
					}
				}
			}
		}
	}

	public bool disable_hover_scale {
		set {
			if (value) {
				image.remove_css_class ("lww-emoji");
			} else {
				image.add_css_class ("lww-emoji");
			}
		}
	}

	construct {
		image = new Gtk.Image () {
			css_classes = { "lww-emoji" }
		};
		child = image;
	}

	public Emoji (string emoji_url, string? t_shortcode = null) {
		this.shortcode = t_shortcode;
		this.emoji_url = emoji_url;
	}

	void on_cache_response (Gdk.Paintable? data) {
		image.paintable = data;
	}
}
