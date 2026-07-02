public class Tuba.Widgets.CollectionRow : Gtk.ListBoxRow {
	public signal void open ();

	API.Collection collection;
	public CollectionRow (API.Collection collection) {
		this.open.connect (on_activated);
		this.activate.connect (on_activated);
		this.collection = collection;
		var w = new Widgets.Collection (collection);
		w.refresh.connect (refresh);
		this.child = w;
	}

	private void on_activated () {
		var dlg = new Dialogs.Collection (this.collection);
		dlg.present (this);
	}

	private void refresh () {
		app.refresh ();
	}
}

public class Tuba.Widgets.CollectionButton : Gtk.Button {
	API.Collection collection;
	public class CollectionButton (API.Collection collection) {
		this.add_css_class ("flat");
		this.add_css_class ("frame");
		this.add_css_class ("collection-button");
		this.collection = collection;
		this.clicked.connect (on_activated);

		this.child = new Widgets.Collection (collection, false);
	}

	private void on_activated () {
		var dlg = new Dialogs.Collection (this.collection);
		dlg.present (this);
	}
}

public class Tuba.Widgets.Collection : Gtk.Box {
	~Collection () {
		debug ("Destroying Collection");
	}

	public class Avatars : Gtk.Box {
		Gtk.Box? box1 = null;
		Gtk.Box? box2 = null;

		public Avatars (string[] account_ids, bool sensitive = false) {
			this.spacing = 2;
			this.orientation = Gtk.Orientation.HORIZONTAL;
			if (sensitive) this.add_css_class ("collection-sensitive");

			if (account_ids.length > 2) {
				this.orientation = Gtk.Orientation.VERTICAL;
				box1 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
				box2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);

				this.append (box1);
				this.append (box2);
			}

				populate.begin (account_ids);

		}

		private async void populate (string[] account_ids) {
			try {
				string[] accounts_arr = {};
				foreach (string acc_id in account_ids) {
					accounts_arr += @"id[]=$(acc_id)";
				}

				var req = new Request.GET (@"/api/v1/accounts?$(string.joinv ("&", accounts_arr))")
					.with_account (accounts.active);
				yield req.await ();

				var parser = Network.get_parser_from_inputstream (req.response_body);
				int i = 0;
				Network.parse_array (parser, node => {
					var acc = API.Account.from (node);
					if (box1 != null && box2 != null) {
						Gtk.Box to_add_to = i % 2 == 0 ? box1 : box2;
						var avi = new Widgets.Avatar () {
							account = acc,
							size = 25,
							overflow = Gtk.Overflow.HIDDEN,
							allow_mini_profile = true
						};
						avi.add_css_class ("no-min-size");
						to_add_to.append (avi);
						i += 1;
					} else {
						this.append (new Widgets.Avatar () {
							account = acc,
							size = account_ids.length == 1 ? 48 : 30,
							overflow = Gtk.Overflow.HIDDEN,
							allow_mini_profile = true
						});
					}
				});
			} catch (Error e) {
				// translators: error message when failing to fetch mastodon collection images
				string msg = _("Couldn't fetch collection images: %s").printf (e.message);
				app.toast (msg);
				warning (msg);
			}
		}
	}

	public signal void refresh ();
	API.Collection collection;
	string collection_self_item_id = "";
	API.Account? author = null;

	private void on_refresh () {
		refresh ();
	}

	private const GLib.ActionEntry[] ACTION_ENTRIES = {
		{"copy-url", on_copy_url},
		{"edit", on_edit},
		{"remove-me", on_remove_me},
		{"report", on_report},
		{"block", on_block},
		{"delete", on_delete},
	};

	private void on_copy_url () {
		Utils.Host.copy (collection.url);
		app.toast (_("Copied url to clipboard"));
	}

	private void on_edit () {
		var dlg = new Dialogs.Collections (this.collection);
		dlg.refresh.connect (on_refresh);
		dlg.present (app.main_window);
	}

	private void on_remove_me () {
		app.question.begin (
			// translators: question dialog title when removing yourself from a Collection; the variable is the collection name string
			{_("Remove yourself from \"%s\"?").printf (collection.name), false},
			null,
			app.main_window,
			{ { _("Remove"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			null,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) {
					new Request.POST (@"/api/v1/collections/$(collection.id)/items/$collection_self_item_id/revoke")
						.with_account (accounts.active)
						.then (() => {
							refresh ();
						})
						.on_error ((code, message) => {
							app.toast (message);
							warning (@"Couldn't remove yourself from collection $(collection.id): $code $message");
						})
						.exec ();
				}
			}
		);
	}

	private void on_report () {
		new Dialogs.Report (this.author, null, null, this.collection);
	}

	private void on_block () {
		app.question.begin (
			{_("Block \"%s\"?").printf (author.handle), false},
			null,
			app.main_window,
			{ { _("Block"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			null,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) block_author ();
			}
		);
	}

	private void on_delete () {
		app.question.begin (
			{_("Delete \"%s\"?").printf (collection.name), false},
			null,
			app.main_window,
			{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			null,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) {
					new Request.DELETE (@"/api/v1/collections/$(collection.id)")
						.with_account (accounts.active)
						.then (() => {
							refresh ();
						})
						.on_error ((code, message) => {
							app.toast (message);
							warning (@"Couldn't delete collection $(collection.id): $code $message");
						})
						.exec ();
				}
			}
		);
	}

	private async void block_author () {
		try {
			var req = new Request.GET ("/api/v1/accounts/relationships")
				.with_account (accounts.active)
				.with_param ("id", collection.account_id);
			yield req.await ();

			var parser = Network.get_parser_from_inputstream (req.response_body);
			Network.parse_array (parser, node => {
				var rs = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
				if (rs != null) {
					rs.modify ("block");
				}
			});
			refresh ();
		} catch (Error e) {
			app.toast (e.message);
			warning (@"Couldn't block $(collection.account_id): $(e.code) $(e.message)");
		}
	}

	public Collection (API.Collection collection, bool has_menu = true) {
		this.add_css_class ("collection");
		this.orientation = Gtk.Orientation.HORIZONTAL;
		this.spacing = 12;
		this.collection = collection;
		bool i_made_it = collection.account_id == accounts.active.id;

		string[] account_ids = {};
		if (collection.items != null && collection.items.size > 0) {
			foreach (API.Collection.Item item in collection.items) {
				if (account_ids.length < 4) account_ids += item.account_id;
				if (!i_made_it) {
					if (item.account_id == accounts.active.id) collection_self_item_id = item.id;
				} else if (account_ids.length >= 4) break;
			}

			this.append (new Avatars (account_ids, collection.sensitive) {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER
			});
		}
		bool i_am_in_it = collection_self_item_id != "";

		Gtk.MenuButton? menu_btn = null;
		if (has_menu) {
			var actions = new GLib.SimpleActionGroup ();
			actions.add_action_entries (ACTION_ENTRIES, this);
			this.insert_action_group ("collection", actions);

			var menu_model = new GLib.Menu ();
			menu_model.append (_("Copy URL"), "collection.copy-url");
			if (i_made_it) menu_model.append (_("Edit"), "collection.edit");
			// translators: menu item, remove myself from mastodon collection
			if (i_am_in_it) menu_model.append (_("Remove Myself"), "collection.remove-me");
			if (!i_made_it) menu_model.append (_("Report"), "collection.report");
			// translators: block mastodon collection author, menu item
			if (i_am_in_it) menu_model.append (_("Block Author"), "collection.block");
			if (i_made_it) menu_model.append (_("Delete"), "collection.delete");

			menu_btn = new Gtk.MenuButton () {
				icon_name = "view-more-horizontal-symbolic",
				tooltip_text = _("Menu"),
				halign = CENTER,
				valign = CENTER,
				css_classes = { "flat" },
				menu_model = menu_model
			};
		}

		var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 2);
		title_box.append (new Gtk.Label (collection.name) {
			ellipsize = Pango.EllipsizeMode.END,
			xalign = 0,
			css_classes = { "font-bold" }
		});
		title_box.append (new Gtk.Label (GLib.ngettext (
						// translators: amount of accounts in a collection, variable is a number
						"%s Account",
						"%s Accounts",
						(ulong) collection.item_count
		).printf ("<b>%s</b>".printf (Utils.Units.shorten (collection.item_count)))) {
			xalign = 0,
			use_markup = true,
			hexpand = true
		});

		this.append (title_box);
		if (has_menu) this.append (menu_btn);

		if (i_made_it) {
			// translators: the variable is a string timestamp of the last time a Collection was updated
			title_box.append (new Gtk.Label ("Last Updated: %s".printf (Utils.DateTime.humanize_aria (collection.updated_at))) {
				xalign = 0,
				hexpand = true
			});
		} else {
			new Request.GET (@"/api/v1/accounts/$(collection.account_id)")
				.with_account (accounts.active)
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					var node = network.parse_node (parser);
					var acc = API.Account.from (node);
					author = acc;

					title_box.append (new Widgets.RichLabel.with_emojis (_("By %s").printf (acc.display_name), acc.emojis_map) {
						use_markup = false,
						ellipsize = true,
						xalign = 0.0f
					});
				})
				.exec ();
		}
	}
}
