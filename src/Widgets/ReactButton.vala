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
		badge.append (reactions_label);
		this.child = badge;

		update_reaction (reaction);
		this.clicked.connect (on_clicked);
	}

	public void update_reaction (API.EmojiReaction reaction) {
		if (reaction.count == 0) removed ();
		update_button_props (reaction.me);
		this.reactions = reaction.count;
	}

	public void update_reacted (bool reacted = true) {
		if (reacted) {
			reactions = reactions + 1;
		} else {
			reactions = reactions - 1;
		}

		if (reactions == 0) removed ();
		update_button_props (reacted);
	}

	private void update_button_props (bool reacted) {
		if (reacted) {
			this.add_css_class ("accent");
			this.update_state (Gtk.AccessibleState.PRESSED, Gtk.AccessibleTristate.TRUE, -1);
		} else {
			this.remove_css_class ("accent");
			this.update_state (Gtk.AccessibleState.PRESSED, Gtk.AccessibleTristate.FALSE, -1);
		}
		_has_reacted = reacted;
	}

	private void on_clicked () {
		reaction_toggled ();
	}
}
