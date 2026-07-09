public class Tuba.Widgets.AccountRow : Gtk.ListBoxRow {
	public signal void checkbox_toggled (bool new_state);
	public signal void button_clicked ();
	public API.Account account { get; private set; }

	Gtk.Box main_box;
	Gtk.CheckButton? selection_button = null;
	Widgets.RelationshipButton? rs_btn = null;

	public API.Relationship rs {
		set {
			if (rs_btn != null) {
				if (rs_btn.rs != null) rs_btn.rs.invalidated.disconnect (on_rs_invalidation);
				rs_btn.rs = value;
				if (rs_btn.rs != null) rs_btn.rs.invalidated.connect (on_rs_invalidation);
			}
		}
	}

	public bool checkbox_sensitive {
		get { return selection_button != null && selection_button.sensitive; }
		set { if (selection_button != null) selection_button.sensitive = value; }
	}

	public bool checkbox_active {
		get { return selection_button != null && selection_button.active; }
		set {
			if (selection_button != null) {
				selection_button.freeze_notify ();
				selection_button.active = value;
				selection_button.thaw_notify ();
			}
		}
	}

	public AccountRow (API.Account account, bool open_only = true) {
		this.activatable = false;
		this.account = account;
		main_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
			vexpand = true,
			margin_bottom = 8,
			margin_end = 8,
			margin_start = 8,
			margin_top = 8
		};
		var avi = new Widgets.Avatar () {
			size = 36,
			allow_mini_profile = true,
			account = account
		};
		main_box.prepend (avi);

		var info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0) {
			hexpand = true
		};
		var title_label = new Widgets.EmojiLabel () {
			use_markup = false
		};
		title_label.instance_emojis = account.emojis_map;
		title_label.content = account.display_name;
		info_box.prepend (title_label);
		info_box.append (new Gtk.Label (account.full_handle) {
			hexpand = true,
			xalign = 0.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			use_markup = false,
			css_classes = {"dim-label"}
		});
		main_box.append (info_box);

		if (open_only) {
			var open_button = new Gtk.Button.with_label (_("Open")) {
				valign = Gtk.Align.CENTER
			};
			open_button.clicked.connect (open);
			main_box.append (open_button);
		}

		this.child = main_box;
	}

	public void add_checkbox (string tooltip_text) {
		if (selection_button != null) return;
		selection_button = new Gtk.CheckButton () {
			valign = Gtk.Align.CENTER,
			css_classes = {"selection-mode"},
			tooltip_text = tooltip_text
		};
		main_box.prepend (selection_button);
		selection_button.notify["active"].connect (on_checkbox_toggled);
	}

	private void on_checkbox_toggled () {
		if (selection_button == null) return;
		checkbox_toggled (selection_button.active);
	}

	public void add_button (string label, string? icon_name = null, string[]? styles = null) {
		var btn = new Gtk.Button () {
			valign = Gtk.Align.CENTER
		};

		if (icon_name != null) {
			btn.icon_name = icon_name;
			btn.tooltip_text = label;
		} else {
			btn.label = label;
		}

		if (styles != null) {
			foreach (string style in styles) {
				btn.add_css_class (style);
			}
		}

		btn.clicked.connect (on_button_clicked);
		main_box.append (btn);
	}

	private void on_button_clicked () {
		button_clicked ();
	}

	void open () {
		this.account.open ();
	}

	public void add_rs_button () {
		rs_btn = new Widgets.RelationshipButton () {
			valign = Gtk.Align.CENTER
		};
		main_box.append (rs_btn);
	}

	public void add (Gtk.Widget widget) {
		main_box.append (widget);
	}

	private void on_rs_invalidation (API.Relationship rs) {
		app.relationship_invalidated (rs);
	}
}
