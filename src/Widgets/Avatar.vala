using Gtk;
using Gdk;

public class Tuba.Widgets.Avatar : Button {

	public API.Account? account { get; set; }
	public int size {
		get { return avatar.size; }
		set { avatar.size = value; }
	}
	public Paintable? custom_image {
		get { return avatar.custom_image; }
	}

	protected Adw.Avatar? avatar {
		get { return child as Adw.Avatar; }
	}
	public string? avatar_url { get; set; }

	construct {
		child = new Adw.Avatar (48, null, true);
		halign = valign = Align.CENTER;
		css_classes = { "flat", "circular", "image-button", "ttl-flat-button" };

		notify["account"].connect (on_invalidated);
		notify["avatar-url"].connect (on_avatar_url_change);
		on_invalidated ();
	}

	void on_avatar_url_change () {
		if (avatar_url == null) return;

		image_cache.request_paintable (avatar_url, on_cache_response);
	}

	void on_invalidated () {
		if (account == null) {
			avatar.text = "d";
			avatar.show_initials = false;
		}
		else {
			avatar.text = account.display_name;
			avatar.show_initials = true;
			image_cache.request_paintable (account.avatar, on_cache_response);
		}
	}

	void on_cache_response (bool is_loaded, owned Paintable? data) {
		avatar.custom_image = data;
	}

}
