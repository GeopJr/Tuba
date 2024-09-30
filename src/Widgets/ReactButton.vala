public class Tuba.Widgets.ReactButton : Gtk.Button {
	private Gtk.Label reactions_label;
	public string shortcode { get; private set; }
	public signal void reaction_toggled ();
	public signal void removed ();

	private bool _has_reacted = false;
	public bool has_reacted {
		get {
			return _has_reacted;
		}
		set {
			_has_reacted = value;
			update_reacted (value);
		}
	}

	private int64 _reactions = 0;
	public int64 reactions {
		get {
			return _reactions;
		}
		set {
			_reactions = value;
			reactions_label.label = value.to_string ();
		}
	}

	public ReactButton (API.EmojiReaction reaction) {
		this.set_accessible_role (Gtk.AccessibleRole.TOGGLE_BUTTON);

		// translators: the variable is the emoji or its name if it's custom
		tooltip_text = _("React with %s").printf (reaction.name);
		shortcode = reaction.name;

		var badge = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		if (reaction.url != null) {
			badge.append (new Widgets.Emoji (reaction.url));
		} else {
			badge.append (new Gtk.Label (reaction.name));
		}

		reactions_label = new Gtk.Label (null);
		reactions = reaction.count;

		badge.append (reactions_label);
		this.child = badge;

		_has_reacted = reaction.me;
		if (reaction.me == true) {
			this.add_css_class ("accent");
			this.update_state (Gtk.AccessibleState.PRESSED, Gtk.AccessibleTristate.TRUE, -1);
		}

		this.clicked.connect (on_clicked);
	}

	public void update_reacted (bool reacted = true) {
		if (reacted) {
			this.add_css_class ("accent");
			reactions = reactions + 1;
			this.update_state (Gtk.AccessibleState.PRESSED, Gtk.AccessibleTristate.TRUE, -1);
		} else {
			this.remove_css_class ("accent");
			reactions = reactions - 1;
			this.update_state (Gtk.AccessibleState.PRESSED, Gtk.AccessibleTristate.FALSE, -1);
		}
		_has_reacted = reacted;

		if (reactions == 0) removed ();
	}

	private void on_clicked () {
		reaction_toggled ();
	}
}
