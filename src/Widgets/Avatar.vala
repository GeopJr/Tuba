using Gtk;
using Gdk;

public class Tooth.Widgets.Avatar : Button {

	public API.Account? account { get; set; }
	public int size {
		get { return avatar.size; }
		set { avatar.size = value; }
	}

	protected Adw.Avatar? avatar {
		get { return child as Adw.Avatar; }
	}

	construct {
		child = new Adw.Avatar (48, null, true);
		halign = valign = Align.CENTER;
		add_css_class ("flat");
		add_css_class ("circular");
		add_css_class ("image-button");
		add_css_class ("ttl-flat-button");

		notify["account"].connect (on_invalidated);
		on_invalidated ();
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
