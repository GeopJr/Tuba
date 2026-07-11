public class Tuba.Dialogs.Collection : Adw.Dialog {
	Adw.HeaderBar headerbar;
	Adw.PreferencesGroup member_group;
	Adw.PreferencesGroup author_group;
	Adw.ToastOverlay toast_overlay;
	string collection_url;

	~Collection () {
		debug ("Destroying Collection");
	}

	public Collection (API.Collection collection) {
		this.title = collection.name;
		collection_url = collection.url;

		this.content_height = this.content_width = 600;
		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
			margin_top = margin_bottom = 12,
			margin_start = 6,
			margin_end = 6
		};

		content_box.append (new Gtk.Label (collection.name) {
			css_classes = {"title-1"},
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			halign = Gtk.Align.CENTER
		});

		if (collection.tag != null) {
			string tag = collection.tag.name.has_prefix ("#") ? collection.tag.name : @"#$(collection.tag.name)";
			content_box.append (new Gtk.Label (tag) {
				css_classes = { "profile-role", "tuba-circular" },
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				halign = Gtk.Align.CENTER
			});
		}

		if (collection.description != null) {
			var markupview = new Widgets.MarkupView () {
				content = collection.description
			};
			content_box.append (markupview);
		}

		var scrolled_window = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true,
			child = new Adw.Clamp () {
				child = content_box,
				tightening_threshold = 100,
				valign = Gtk.Align.START
			}
		};

		toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			hexpand = true,
			child = scrolled_window
		};

		var toolbar_view = new Adw.ToolbarView () {
			content = toast_overlay
		};
		headerbar = new Adw.HeaderBar () {
			show_title = false
		};
		var copy_btn = new Gtk.Button.with_label (_("Copy URL")) {
			css_classes = {"suggested-action"}
		};
		copy_btn.clicked.connect (on_copy_clicked);
		headerbar.pack_end (copy_btn);
		toolbar_view.add_top_bar (headerbar);

		this.child = toolbar_view;
		scrolled_window.vadjustment.value_changed.connect (on_vadjustment_changed);

		member_group = new Adw.PreferencesGroup () {
			title = GLib.ngettext ("%d Member", "%d Members", (ulong) collection.items.size).printf (collection.items.size)
		};
		content_box.append (member_group);

		author_group = new Adw.PreferencesGroup () {
			// translators: title of a list of users that created a collection
			title = _("Created By")
		};
		content_box.append (author_group);

		gather_accounts.begin (collection);
	}

	private async void gather_accounts (API.Collection collection) throws Error {
		string[] accounts_arr = {@"id[]=$(collection.account_id)"};
		string[] account_ids = {collection.account_id};
		GLib.HashTable<string, string> states = new GLib.HashTable<string, string> (str_hash, str_equal);
		collection.items.foreach (e => {
			accounts_arr += @"id[]=$(e.account_id)";
			account_ids += e.account_id;
			states.insert (e.account_id, e.state);
			return true;
		});

		var req = new RequestV2 (@"/api/v1/accounts?$(string.joinv ("&", accounts_arr))") { account = accounts.active };
		var in_stream = yield req.exec (null);

		Widgets.AccountRow[] widgets = {};
		Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
		bool did_author = false;
		Network.parse_array (parser, node => {
			var acc = API.Account.from (node);
			var widget = new Widgets.AccountRow (acc, false);
			widgets += widget;
			if (acc.id == collection.account_id && !did_author) {
				author_group.add (widget);
				did_author = true;
			} else {
				if (states.get (acc.id) == "pending") widget.add (new Gtk.Label (_("Pending")) {
					css_classes = {"warning", "profile-role", "tuba-circular"},
					tooltip_text = _("Pending"),
					ellipsize = END,
					valign = Gtk.Align.CENTER
				});
				member_group.add (widget);
			}
			if (acc.id != accounts.active.id) widget.add_rs_button ();
		});

		Gee.HashMap<string, API.Relationship> relationships = yield API.Relationship.request_many (account_ids);
		foreach (var widget in widgets) {
			widget.rs = relationships.get (widget.account.id);
		}
	}

	private void on_vadjustment_changed (Gtk.Adjustment vadjustment) {
		headerbar.show_title = vadjustment.value > 10;
	}

	private void on_copy_clicked () {
		Utils.Host.copy (collection_url);
		toast_overlay.add_toast (new Adw.Toast (_("Copied url to clipboard")) {
			timeout = 5
		});
	}
}
