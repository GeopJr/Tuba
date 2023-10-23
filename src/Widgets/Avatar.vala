public class Tuba.Widgets.Avatar : Gtk.Button {
	public API.Account? account {
		set {
			on_invalidated (value);
		}
	}

	public int size {
		get { return avatar.size; }
		set { avatar.size = value; }
	}

	public Gdk.Paintable? custom_image {
		get { return avatar.custom_image; }
	}

	protected Adw.Avatar? avatar {
		get { return child as Adw.Avatar; }
	}

	string? _avatar_url = null;
	public string? avatar_url {
		get {
			return _avatar_url;
		}

		set {
			_avatar_url = value;

			if (value != null) {
				Tuba.ImageCache.request_paintable (value, on_cache_response);
			}
		}
	}

	construct {
		child = new Adw.Avatar (48, null, true);
		halign = valign = Gtk.Align.CENTER;
		css_classes = { "flat", "circular", "image-button", "ttl-flat-button" };

		on_invalidated ();
	}

	void on_invalidated (API.Account? account = null) {
		if (account == null) {
			avatar.text = "d";
			avatar.show_initials = false;
		} else {
			avatar.text = account.display_name;
			avatar.show_initials = true;
			Tuba.ImageCache.request_paintable (account.avatar, on_cache_response);
		}
	}

	void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
		if (is_loaded)
			avatar.custom_image = data;
	}
}
