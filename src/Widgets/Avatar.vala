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

			if (value != null && (!retry_on_network_changes || (retry_on_network_changes && app.is_online))) {
				Tuba.Helper.Image.request_paintable (value, null, on_cache_response);
			}
		}
	}

	bool _retry_on_network_changes = false;
	public bool retry_on_network_changes {
		get {
			return _retry_on_network_changes;
		}

		set {
			if (_retry_on_network_changes == value) return;

			if (value) {
				app.notify["is-online"].connect (on_network_change);
			} else {
				app.notify["is-online"].disconnect (on_network_change);
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
			avatar_url = account.avatar;
		}
	}

	void on_cache_response (Gdk.Paintable? data) {
		avatar.custom_image = data;
	}

	private void on_network_change () {
		if (app.is_online && _avatar_url != null && custom_image == null) {
			// If the previous avi url failed or is pending,
			// libsoup might crash if we queue it again
			// so instead add a UUID as a fragment
			string new_uuid = GLib.Uuid.string_random ();
			string new_avi = _avatar_url;

			if (_avatar_url.contains ("#")) {
				new_avi = _avatar_url.slice (0, _avatar_url.index_of_char ('#'));
			}

			this.avatar_url = @"$new_avi#$new_uuid";
		}
	}
}
