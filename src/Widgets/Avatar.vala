public class Tuba.Widgets.Avatar : Gtk.Button {
	public signal void mini_clicked ();

	weak API.Account? _account = null;
	public API.Account? account {
		set {
			on_invalidated (value);
			_account = value;
		}
	}

	bool _allow_mini_profile = false;
	public bool allow_mini_profile {
		get { return _allow_mini_profile; }
		set {
			if (_allow_mini_profile == value) return;

			_allow_mini_profile = value;
			if (value) {
				this.clicked.connect (show_mini_profile);
			} else {
				this.clicked.disconnect (show_mini_profile);
			}
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
				Tuba.Helper.Image.request_paintable (value, null, false, on_cache_response);
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
		this.notify_property ("custom-image");
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

	Gtk.Popover? mini_profile = null;
	private void show_mini_profile () {
		if (_account == null) return;

		if (mini_profile == null) {
			var mini_cover = new Views.Profile.ProfileAccount (_account).to_mini_widget ();
			((Widgets.Cover) mini_cover).avatar_clicked.connect (on_mini_avatar_clicked);

			mini_profile = new Gtk.Popover () {
				child = new Gtk.ScrolledWindow () {
					child = mini_cover,
					hexpand = true,
					vexpand = true,
					hscrollbar_policy = Gtk.PolicyType.NEVER,
					max_content_height = 500,
					width_request = 360,
					propagate_natural_height = true
				}
			};
			mini_profile.add_css_class ("mini-profile");
			mini_profile.set_parent (this);
			mini_profile.closed.connect (clear_mini);
		}

		mini_profile.popup ();
	}

	private void clear_mini () {
		if (mini_profile == null) return;

		mini_profile.unparent ();
		mini_profile.dispose ();
		mini_profile = null;
	}

	private void on_mini_avatar_clicked () {
		if (mini_profile != null) mini_profile.popdown ();
		this.grab_focus ();
		mini_clicked ();
	}

	~Avatar () {
		clear_mini ();
	}
}
