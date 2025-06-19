// Inspired by https://gitlab.gnome.org/World/amberol/-/blob/638eef0ba2b8ac6fac32a51241161fa25317fa18/src/drag_overlay.rs
public class Tuba.Dialogs.Components.DropOverlay : Adw.Bin {
	static construct {
		set_css_name ("dropoverlay");
	}

	public Gtk.Widget? overlay_child {
		get { return overlay.child; }
		set { overlay.child = value; }
	}

	public bool dropping {
		get { return revealer.reveal_child; }
		set {
			revealer.reveal_child = value;
		}
	}

	public string title {
		get { return status_page.title; }
		set { status_page.title = value; }
	}

	public bool compact {
		get { return status_page.has_css_class ("compact"); }
		set {
			if (this.compact != value) {
				if (value) {
					status_page.add_css_class ("compact");
				} else {
					status_page.remove_css_class ("compact");
				}
			}
		}
	}

	public string icon_name {
		get { return status_page.icon_name; }
		set { status_page.icon_name = value; }
	}

	Gtk.Overlay overlay;
	Gtk.Revealer revealer;
	Adw.StatusPage status_page;
	construct {
		overlay = new Gtk.Overlay ();

		status_page = new Adw.StatusPage () {
			icon_name = "tuba-image-round-symbolic",
			css_classes = { "status" }
		};

		revealer = new Gtk.Revealer () {
			child = status_page,
			can_target = false,
			transition_type = Gtk.RevealerTransitionType.CROSSFADE,
			transition_duration = 800
		};
		overlay.add_overlay (revealer);

		this.child = overlay;
	}
}
