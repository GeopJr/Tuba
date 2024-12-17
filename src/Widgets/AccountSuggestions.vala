public class Tuba.Widgets.AccountSuggestions : Gtk.ListBoxRow {
	public class AccountSuggestion : Gtk.Box {
		Widgets.RelationshipButton rsbtn;
		API.Account acc;
		public AccountSuggestion (API.Account acc) {
			this.acc = acc;
			this.orientation = Gtk.Orientation.VERTICAL;
			this.spacing = 12;
			this.width_request = 120;
			this.margin_start = this.margin_end = this.margin_top = this.margin_bottom = 12;

			var avi = new Widgets.Avatar () {
				account = acc,
				size = 64,
				tooltip_text = _("Open %s's Profile").printf (acc.full_handle)
			};
			avi.clicked.connect (on_clicked);
			this.append (avi);

			var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 3);
			var title_label = new Widgets.EmojiLabel () {
				use_markup = false,
				ellipsize = true,
				halign = Gtk.Align.CENTER,
				tooltip_text = acc.display_name
			};
			title_label.instance_emojis = acc.emojis_map;
			title_label.content = acc.display_name;
			title_box.append (title_label);
			title_box.append (new Gtk.Label (acc.full_handle) {
				hexpand = true,
				xalign = 0.0f,
				single_line_mode = true,
				ellipsize = Pango.EllipsizeMode.END,
				use_markup = false,
				css_classes = {"dim-label"},
				tooltip_text = acc.full_handle,
				halign = Gtk.Align.CENTER
			});
			this.append (title_box);

			rsbtn = new Widgets.RelationshipButton () {
				handle = acc.full_handle,
				visible = false
			};
			this.append (rsbtn);
		}

		public void update_rs (API.Relationship? new_rs) {
			rsbtn.visible = new_rs != null;
			rsbtn.rs = new_rs;
		}

		private void on_clicked () {
			this.acc.open ();
		}
	}

	Gtk.ScrolledWindow scrolled_window;
	Gtk.Box account_box;
	Gtk.Button back_button;
	Gtk.Button next_button;
	construct {
		this.visible = false;
		this.activatable = false;

		account_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		scrolled_window = new Gtk.ScrolledWindow () {
			child = account_box,
			vscrollbar_policy = Gtk.PolicyType.NEVER
		};

		var overlay = new Gtk.Overlay () {
			child = scrolled_window
		};

		back_button = new Gtk.Button.from_icon_name ("tuba-left-large-symbolic") {
			css_classes = { "circular", "osd" },
			tooltip_text = _("Back"),
			halign = Gtk.Align.START,
			valign = Gtk.Align.CENTER,
			margin_start = margin_end = 3
		};
		back_button.clicked.connect (prev_page);
		overlay.add_overlay (back_button);

		next_button = new Gtk.Button.from_icon_name ("tuba-right-large-symbolic") {
			css_classes = { "circular", "osd" },
			tooltip_text = _("Next"),
			halign = Gtk.Align.END,
			valign = Gtk.Align.CENTER,
			margin_start = margin_end = 3
		};
		next_button.clicked.connect (next_page);
		overlay.add_overlay (next_button);

		var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		//  translators: title of a list of suggested people to follow.
		//				 Basically 'Who to follow'
		header_box.append (new Gtk.Label (_("Follow Suggestions")) {
			wrap = true,
			hexpand = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			xalign = 0.0f,
			css_classes = { "heading" },
			margin_start = 12,
			margin_end = 12,
			margin_top = 6,
			margin_bottom = 6
		});

		var dra_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			tooltip_text = _("Don't remind me again"),
			css_classes = { "circular", "error" },
			margin_start = margin_end = margin_top = margin_bottom = 6
		};
		dra_button.clicked.connect (on_dra_clicked);
		header_box.append (dra_button);

		var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		main_box.append (header_box);
		main_box.append (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
		main_box.append (overlay);

		this.child = main_box;
		on_page_changed ();

		GLib.Idle.add (populate_account_suggestions);
		scrolled_window.hadjustment.value_changed.connect (on_page_changed);
	}

	private void next_page () {
		double new_val = scrolled_window.hadjustment.value + scrolled_window.hadjustment.page_increment / 2;
		double end = scrolled_window.hadjustment.upper - scrolled_window.hadjustment.page_size;

		if (new_val + 42 > end) {
			scrolled_window.hadjustment.value = end;
		} else {
			scrolled_window.hadjustment.value = new_val;
		}
	}

	private void prev_page () {
		double new_val = scrolled_window.hadjustment.value - scrolled_window.hadjustment.page_increment / 2;

		if (new_val - 42 < 0) {
			scrolled_window.hadjustment.value = 0;
		} else {
			scrolled_window.hadjustment.value = new_val;
		}
	}

	private bool populate_account_suggestions () {
		new Request.GET ("/api/v2/suggestions")
			.with_account (accounts.active)
			.with_param ("limit", "10")
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);

				Gee.HashMap<string, AccountSuggestion> widgets = new Gee.HashMap<string, AccountSuggestion> ();
				Gtk.Widget? last_sep = null;
				Network.parse_array (parser, node => {
					var entity = Tuba.Helper.Entity.from_json (node, typeof (API.Suggestion)) as API.Suggestion;
					if (entity != null) {
						var widget = new AccountSuggestion (((API.Suggestion) entity).account);
						widgets.set (((API.Suggestion) entity).account.id, widget);
						account_box.append (widget);

						last_sep = new Gtk.Separator (Gtk.Orientation.VERTICAL);
						account_box.append (last_sep);
					}
				});

				if (last_sep != null) account_box.remove (last_sep);
				if (widgets.size > 0) {
					this.visible = true;
					populate_account_suggestions_relationships (widgets);
				} else {
					this.visible = false;
				}
				on_page_changed ();
			})
			.on_error (() => {
				this.visible = false;
			})
			.exec ();

		return GLib.Source.REMOVE;
	}

	private bool populate_account_suggestions_relationships (Gee.HashMap<string, AccountSuggestion> account_widgets) {
		API.Relationship.request_many.begin (account_widgets.keys.to_array (), (obj, res) => {
			try {
				Gee.HashMap<string, API.Relationship> relationships = API.Relationship.request_many.end (res);

				if (relationships.size > 0) {
					relationships.foreach (e => {
						if (account_widgets.has_key (e.key)) {
							account_widgets.get (e.key).update_rs (e.value);
						}

						return true;
					});

					account_widgets.clear ();
					on_page_changed ();
				}
			} catch (Error e) {
				warning (e.message);
			}
		});

		return GLib.Source.REMOVE;
	}

	private void on_page_changed () {
		back_button.visible = scrolled_window.hadjustment.value > 0;
		next_button.visible = scrolled_window.hadjustment.value < scrolled_window.hadjustment.upper - scrolled_window.hadjustment.page_size;
	}

	private void on_dra_clicked () {
		this.visible = false;
		settings.account_suggestions = false;
	}
}
