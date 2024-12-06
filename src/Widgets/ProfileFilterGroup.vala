// Ported partially from Elastic https://gitlab.gnome.org/World/elastic
// TODO: remove on libadwaita 1.7
public class Tuba.Widgets.ProfileFilterGroup : Gtk.ListBoxRow {
	public enum Filter {
		POSTS,
		REPLIES,
		MEDIA
	}
	public signal void filter_change (Filter filter);

	class FilterToggleButton : Gtk.ToggleButton {
		public Filter filter { get; set; }

		static construct {
			set_accessible_role (Gtk.AccessibleRole.RADIO);
		}

		construct {
			this.add_css_class ("flat");
		}

		public FilterToggleButton (string label, Filter filter) {
			this.label = label;
			this.filter = filter;
		}
	}

	static construct {
		set_accessible_role (Gtk.AccessibleRole.RADIO_GROUP);
	}

	construct {
		Gtk.Box box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		this.focusable = true;
		this.activatable = false;
		this.child = box;
		this.add_css_class ("toggle-group-17");

		var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
		var toggle_button_posts = new FilterToggleButton (_("Posts"), Filter.POSTS) {
			hexpand = true
		};
		toggle_button_posts.active = true;
		sizegroup.add_widget (toggle_button_posts);
		box.append (toggle_button_posts);
		toggle_button_posts.state_flags_changed.connect (on_state_flags_changed);
		toggle_button_posts.toggled.connect (on_toggled);

		var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL) {
			visible = false
		};
		box.append (separator);

		var toggle_button = new FilterToggleButton (_("Replies"), Filter.REPLIES) {
			hexpand = true
		};
		toggle_button.group = toggle_button_posts;
		sizegroup.add_widget (toggle_button);
		box.append (toggle_button);
		toggle_button.state_flags_changed.connect (on_state_flags_changed);
		toggle_button.toggled.connect (on_toggled);

		separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		toggle_button = new FilterToggleButton (_("Media"), Filter.MEDIA) {
			hexpand = true
		};
		toggle_button.add_css_class ("flat");
		toggle_button.group = toggle_button_posts;
		sizegroup.add_widget (toggle_button);
		box.append (toggle_button);
		toggle_button.state_flags_changed.connect (on_state_flags_changed);
		toggle_button.toggled.connect (on_toggled);
	}

	private void update_separator (Gtk.Widget separator) {
        var prev_button = separator.get_prev_sibling ();
        var next_button = separator.get_next_sibling ();

        separator.visible = prev_button != null && next_button != null;

        if (should_hide_separators (prev_button) ||
            should_hide_separators (next_button))
            separator.add_css_class ("hidden");
        else
            separator.remove_css_class ("hidden");
    }

	private bool should_hide_separators (Gtk.Widget? widget) {
        if (widget == null) return true;

        var flags = widget.get_state_flags ();
        if ((flags & (Gtk.StateFlags.PRELIGHT |
                      Gtk.StateFlags.ACTIVE |
                      Gtk.StateFlags.CHECKED)) != 0)
            return true;

        if ((flags & Gtk.StateFlags.FOCUSED) != 0 &&
            (flags & Gtk.StateFlags.FOCUS_VISIBLE) != 0)
            return true;

        return false;
    }

	private void on_state_flags_changed (Gtk.Widget button, Gtk.StateFlags flags) {
		var prev_separator = button.get_prev_sibling ();
		var next_separator = button.get_next_sibling ();

		if (prev_separator != null)
			update_separator (prev_separator);

		if (next_separator != null)
			update_separator (next_separator);
	}

	private void on_toggled (Gtk.ToggleButton toggle_button) {
		if (toggle_button.active)
			filter_change (((FilterToggleButton) toggle_button).filter);
	}
}
