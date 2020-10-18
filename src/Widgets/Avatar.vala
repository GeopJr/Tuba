using Gtk;
using Gdk;

public class Tootle.Widgets.Avatar : Bin {

	Cache.Reference? cached;

	Hdy.Avatar avatar;

	public int size {
		get {
			return avatar.size;
		}
		set {
			avatar.size = value;
		}
	}

	public API.Account? account { get; set; }

	construct {
		avatar = new Hdy.Avatar (48, null, true);
		avatar.destroy.connect (() => {
			avatar.set_image_load_func (null);
		});
		add (avatar);
		show_all ();

		notify["account"].connect (on_invalidated);
		on_invalidated ();
	}

	~Avatar () {
		notify["account"].disconnect (on_invalidated);
		cache.unload (ref cached);
	}

	void on_invalidated () {
		if (cached != null)
			cache.unload (ref cached);

		cached = null;

		if (account != null)
			cache.load (account.avatar, on_cache_result);
		else
			on_cache_result (null);
	}

	void on_cache_result (Cache.Reference? result) {
		cached = result;
		if (account == null) {
			// This exact string makes the avatar grey.
			//
			// If left null, *each* blank Hdy.Avatar receives
			// a random color and hurts my eyes. No bueno.
			avatar.text = "abc";
			avatar.show_initials = false;
		}
		else if (cached != null) {
			avatar.text = account.display_name;
			avatar.show_initials = true;
		}
		avatar.set_image_load_func (avatar_set_pixbuf);
	}

	Pixbuf? avatar_set_pixbuf (int size) {
		if (cached == null || cached.data == null)
			return null;
		else {
			var pb = cached.data;
			if (pb.width != size)
				return pb.scale_simple (size, size, InterpType.BILINEAR);
			else
				return pb;
		}
	}

}
