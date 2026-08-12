public class Tuba.Widgets.AccountRow : Gtk.ListBoxRow {
	public signal void checkbox_toggled (bool new_state);
	public signal void button_clicked ();
	public signal void open ();
	public API.Account account { get; private set; }

	Gtk.Box main_box;
	Gtk.Box info_box;
	Gtk.CheckButton? selection_button = null;
	Widgets.RelationshipButton? rs_btn = null;
	Gtk.Label? note = null;

	public API.Relationship rs {
		get { return rs_btn == null ? null : rs_btn.rs; }
		set {
			if (rs_btn != null) {
				if (rs_btn.rs != null) rs_btn.rs.invalidated.disconnect (on_rs_invalidation);
				rs_btn.rs = value;
				if (rs_btn.rs != null) rs_btn.rs.invalidated.connect (on_rs_invalidation);
				rs_btn.visible = rs_btn.rs != null;
				update_note ();
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

		info_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2) {
			hexpand = true
		};
		var title_label = new Widgets.EmojiLabel () {
			use_markup = false
		};
		title_label.instance_emojis = account.emojis_map;
		title_label.content = account.display_name;

		var info_wrap_box = new Adw.WrapBox () {
			child_spacing = 4
		};
		info_wrap_box.append (title_label);
		info_wrap_box.append (new Gtk.Label (account.full_handle) {
			hexpand = true,
			xalign = 0.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			use_markup = false,
			css_classes = {"dim-label"}
		});
		info_box.append (info_wrap_box);
		main_box.append (info_box);

		if (open_only) {
			var open_button = new Gtk.Button.with_label (_("Open")) {
				valign = Gtk.Align.CENTER
			};
			open_button.clicked.connect (open_clicked);
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

	void open_clicked () {
		this.account.open ();
	}

	public void add_rs_button (bool from_acc = false) {
		rs_btn = new Widgets.RelationshipButton () {
			valign = Gtk.Align.CENTER
		};
		main_box.append (rs_btn);

		if (from_acc) {
			this.rs = this.account.tuba_rs;
			this.account.notify["tuba-rs"].connect (on_tuba_rs);
		}

		app.relationship_invalidated.connect (on_relationship_invalidated_global);
	}

	private void on_tuba_rs () {
		if (account != null && account.tuba_rs != null)
			this.rs = account.tuba_rs;
	}

	public void enable_activation () {
		this.activatable = true;
		open.connect (account.open);
	}

	public void add_followers_and_verified_link () {
		string sub_string = GLib.ngettext (
			"%s Follower",
			"%s Followers",
			(ulong) this.account.followers_count
		).printf (@"<b>$(Utils.Units.shorten (this.account.followers_count))</b>");

		var info_wrap_box = new Adw.WrapBox () {
			child_spacing = 4,
			line_spacing = 4
		};
		info_wrap_box.append (new Gtk.Label (sub_string) {
			xalign = 0.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			use_markup = true
		});

		if (this.account.fields != null && this.account.fields.size > 0) {
			foreach (API.AccountField f in this.account.fields) {
				if (f.verified_at != null && f.verified_at != "") {
					var box = new Gtk.Box (HORIZONTAL, 4) {
						css_classes = {"verified-link"}
					};

					var verified_date = f.verified_at.slice (0, f.verified_at.last_index_of ("T"));
					box.append (new Gtk.Image.from_icon_name ("tuba-verified-checkmark-symbolic") {
						tooltip_text = _(@"Ownership of this link was checked on $verified_date")
					});
					box.append (new Gtk.Label (Utils.Htmlx.simplify (f.val)) {
						xalign = 0.0f,
						wrap = true,
						wrap_mode = Pango.WrapMode.WORD_CHAR,
						use_markup = true
					});
					info_wrap_box.append (box);
					break;
				}
			}
		}

		info_box.append (info_wrap_box);
	}

	public void add_note () {
		if (note != null) return;
		note = new Gtk.Label ("") {
			xalign = 0.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			use_markup = true,
			css_classes = { "italic", "dim-label" },
			visible = false
		};
		info_box.append (note);
		update_note ();
	}

	private void update_note () {
		if (note == null) return;
		if (this.rs != null && this.rs.note != null && this.rs.note != "") {
			note.label = @"“$(this.rs.note.strip ())”";
			note.visible = true;
		} else {
			note.visible = false;
		}
	}

	public void add (Gtk.Widget widget) {
		main_box.append (widget);
	}

	private void on_rs_invalidation (API.Relationship rs) {
		app.relationship_invalidated (rs);
		if (note != null) update_note ();
	}

	private void on_relationship_invalidated_global (API.Relationship new_relationship) {
		if (this.rs == null || this.rs.id != new_relationship.id) return;

		this.rs = new_relationship;
	}
}
