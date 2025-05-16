public class Tuba.Widgets.ProfileFilterGroup : Gtk.ListBoxRow {
	public enum Filter {
		POSTS,
		REPLIES,
		MEDIA;

		public string to_string () {
			switch (this) {
				case POSTS:
					return "posts";
				case REPLIES:
					return "replies";
				default:
					return "media";
			}
		}

		public static Filter from_string (string filter) {
			switch (filter) {
				case "posts":
					return POSTS;
				case "replies":
					return REPLIES;
				default:
					return MEDIA;
			}
		}
	}
	public signal void filter_change (Filter filter);

	Adw.ToggleGroup toggle_group;
	construct {
		toggle_group = new Adw.ToggleGroup ();
		this.focusable = true;
		this.activatable = false;
		this.child = toggle_group;
		this.add_css_class ("toggle-group-17");

		toggle_group.add (new Adw.Toggle () {
			label = _("Posts"),
			name = Filter.POSTS.to_string (),
			enabled = true
		});

		toggle_group.add (new Adw.Toggle () {
			label = _("Replies"),
			name = Filter.REPLIES.to_string ()
		});

		toggle_group.add (new Adw.Toggle () {
			label = _("Media"),
			name = Filter.MEDIA.to_string ()
		});

		toggle_group.notify["active-name"].connect (on_active_changed);
	}

	private void on_active_changed () {
		string? filter_name = toggle_group.active_name;
		if (filter_name != null) {
			filter_change (Filter.from_string (filter_name));
		}
	}
}
