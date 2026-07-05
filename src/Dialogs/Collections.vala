public class Tuba.Dialogs.Collections : Adw.PreferencesDialog {
	const int MAX_MEMBERS = 25;

	~Collections () {
		debug ("Destroying Collections");
		clear ();
	}

	public signal void refresh ();
	bool edit_mode = false;
	string collection_id = "";
	Adw.EntryRow name_row;
	Adw.EntryRow description_row;
	Adw.EntryRow topic_row;
	Adw.PreferencesGroup search_group;
	Adw.PreferencesGroup details_group;
	Widgets.AccountRow[] search_results = {};
	Gtk.Widget[] tag_results = {};
	Adw.EntryRow search_row;
	Adw.PreferencesGroup members_group;
	Gee.HashMap<string, Widgets.AccountRow> members = new Gee.HashMap<string, Widgets.AccountRow> ();
	Gee.HashMap<string, string> members_collection_items = new Gee.HashMap<string, string> ();
	Gtk.CheckButton cw_checkbox;
	Gtk.CheckButton public_checkbox;
	Gtk.CheckButton unlisted_checkbox;
	Adw.ComboRow lang_row;

	string last_name = "";
	string last_description = "";
	uint last_lang = 0;
	string last_topic = "";
	bool last_cw = false;
	bool last_disco = false;

	private void clear () {
		search_results = {};
		tag_results = {};

		if (search_timeout_id > 0) {
			GLib.Source.remove (search_timeout_id);
		}

		if (tag_timeout_id > 0) {
			GLib.Source.remove (tag_timeout_id);
		}
		members.clear ();
		members_collection_items.clear ();
	}

	private void on_closed () {
		clear ();
		if (edit_mode) refresh ();
	}

	private async bool patch_collection (string key, string value) throws Error {
		if (!edit_mode) return false;

		var req = new Request.PATCH (@"/api/v1/collections/$(this.collection_id)")
					.with_account (accounts.active)
					.with_form_data (key, value);

		yield req.await ();
		return true;
	}

	private void update_collection_name (Adw.EntryRow row) {
		patch_entry_row.begin ("name", row, (obj, res) => {
			if (!patch_entry_row.end (res)) {
				row.text = last_name;
			} else {
				last_name = row.text;
			}
		});
	}

	private void update_collection_description (Adw.EntryRow row) {
		patch_entry_row.begin ("description", row, (obj, res) => {
			if (!patch_entry_row.end (res)) {
				row.text = last_description;
			} else {
				last_description = row.text;
			}
		});
	}

	private void update_collection_topic (Adw.EntryRow row) {
		if (!row.text.has_prefix ("#")) row.text = @"#$(row.text)";
		patch_entry_row.begin ("tag_name", row, (obj, res) => {
			if (!patch_entry_row.end (res)) {
				row.text = last_topic;
			} else {
				last_topic = row.text;
			}
		});
	}

	private async bool patch_entry_row (string key, Adw.EntryRow row) {
		try {
			return yield patch_collection (key, row.text);
		} catch (Error e) {
			this.add_toast (new Adw.Toast (e.message) {
				timeout = 5
			});
			warning (@"Error while updating collection $key: $(e.code) $(e.message)");
		}

		return false;
	}

	private void on_lang_changed () {
		if (lang_row.selected == Gtk.INVALID_LIST_POSITION) return;

		var locale_obj = lang_row.selected_item as Utils.Locales.Locale;
		if (locale_obj == null || locale_obj.locale == null) return;

		patch_collection.begin ("language", locale_obj.locale, (obj, res) => {
			try {
				if (!patch_collection.end (res)) {
					lang_row.selected = last_lang;
				} else {
					last_lang = lang_row.selected;
				}
			} catch (Error e) {
				this.add_toast (new Adw.Toast (e.message) {
					timeout = 5
				});
				warning (@"Error while updating collection language: $(e.code) $(e.message)");
				lang_row.selected = last_lang;
			}
		});
	}

	private void on_sensitive_changed () {
		patch_collection.begin ("sensitive", cw_checkbox.active.to_string (), (obj, res) => {
			try {
				if (!patch_collection.end (res)) {
					cw_checkbox.active = last_cw;
				} else {
					last_cw = cw_checkbox.active;
				}
			} catch (Error e) {
				this.add_toast (new Adw.Toast (e.message) {
					timeout = 5
				});
				warning (@"Error while updating collection sensitive: $(e.code) $(e.message)");
				cw_checkbox.active = last_cw;
			}
		});
	}

	private void on_disc_changed () {
		patch_collection.begin ("discoverable", public_checkbox.active ? "true" : "false", (obj, res) => {
			try {
				if (!patch_collection.end (res)) {
					public_checkbox.active = last_disco;
					unlisted_checkbox.active = !last_disco;
				} else {
					last_disco = public_checkbox.active;
				}
			} catch (Error e) {
				this.add_toast (new Adw.Toast (e.message) {
					timeout = 5
				});
				warning (@"Error while updating collection discoverable: $(e.code) $(e.message)");
				public_checkbox.active = last_disco;
				unlisted_checkbox.active = !last_disco;
			}
		});
	}

	public Collections (API.Collection? collection = null) {
		this.edit_mode = collection != null;
		if (edit_mode) this.collection_id = collection.id;

		this.can_close = edit_mode;
		this.closed.connect (on_closed);
		this.title = edit_mode ? collection.name : _("New Collection");
		var collection_page = new Adw.PreferencesPage () {
			// translators: Mastodon collection settings page title
			title = _("Collection"),
			icon_name = "tuba-shapes-symbolic"
		};
		details_group = new Adw.PreferencesGroup ();
		name_row = new Adw.EntryRow () {
			// translators: entry row title
			title = _("Name"),
			max_length = 40,
			show_apply_button = edit_mode
		};
		if (edit_mode) {
			last_name =
			name_row.text = collection.name;
			name_row.apply.connect (update_collection_name);
		}

		description_row = new Adw.EntryRow () {
			// translators: entry row title
			title = _("Description"),
			max_length = 100,
			show_apply_button = edit_mode
		};
		if (edit_mode) {
			if (collection.description != null) last_description = description_row.text = collection.description;
			description_row.apply.connect (update_collection_description);
		}

		topic_row = new Adw.EntryRow () {
			// translators: entry row title in Collection creation dialog, it's a hashtag
			title = _("Topic"),
			max_length = 100,
			show_apply_button = edit_mode
		};
		if (edit_mode) {
			if (collection.tag != null) last_topic = topic_row.text = collection.tag.name;
			topic_row.apply.connect (update_collection_topic);
		}
		topic_row.changed.connect (on_tag_search_changed);

		lang_row = new Adw.ComboRow () {
			title = _("Language"),
			enable_search = true,
			expression = new Gtk.PropertyExpression (typeof (Utils.Locales.Locale), null, "name")
		};
		lang_row.list_factory = new Gtk.BuilderListItemFactory.from_resource (
			null,
			@"$(Build.RESOURCES)gtk/dropdown/language.ui"
		);
		lang_row.model = app.app_locales.list_store;

		var default_language = settings.default_language == "" ? "en" : settings.default_language;
		if (edit_mode) default_language = collection.language;
		uint default_lang_index;
		if (
			app.app_locales.list_store.find_with_equal_func (
				new Utils.Locales.Locale (default_language, null, null),
				Utils.Locales.Locale.compare,
				out default_lang_index
			)
		) {
			last_lang =
			lang_row.selected = default_lang_index;
		}
		if (edit_mode) lang_row.notify["selected"].connect (on_lang_changed);

		details_group.add (name_row);
		details_group.add (description_row);
		details_group.add (lang_row);
		details_group.add (topic_row);

		var visibility_group = new Adw.PreferencesGroup () {
			title = _("Visibility")
		};
		public_checkbox = new Gtk.CheckButton () {
			valign = Gtk.Align.CENTER,
			active = !edit_mode || (edit_mode && collection.discoverable)
		};
		unlisted_checkbox = new Gtk.CheckButton () {
			valign = Gtk.Align.CENTER,
			group = public_checkbox,
			active = !public_checkbox.active
		};

		var p1 = new Adw.ActionRow () {
			title = _("Public"),
			activatable_widget = public_checkbox,
			// translators: collection visibility checkbox description
			subtitle = _("Discoverable in search results and other areas where recommendations appear.")
		};
		p1.add_prefix (public_checkbox);
		visibility_group.add (p1);

		var p2 = new Adw.ActionRow () {
			title = _("Unlisted"),
			activatable_widget = unlisted_checkbox,
			// translators: collection visibility checkbox description
			subtitle = _("Visible to anyone with a link. Hidden from search results and recommendations.")
		};
		p2.add_prefix (unlisted_checkbox);
		visibility_group.add (p2);

		var cw_group = new Adw.PreferencesGroup () {
			title = _("Content Warning")
		};
		cw_checkbox = new Gtk.CheckButton () {
			valign = Gtk.Align.CENTER,
			active = edit_mode && collection.sensitive
		};

		var c3 = new Adw.ActionRow () {
			title = _("Mark as sensitive"),
			activatable_widget = cw_checkbox,
			// translators: collection checkbox description
			subtitle = _("Hides the collection's description and accounts behind a content warning. The collection name will still be visible.")
		};
		c3.add_prefix (cw_checkbox);
		cw_group.add (c3);

		collection_page.add (details_group);
		collection_page.add (visibility_group);
		collection_page.add (cw_group);

		var members_page = new Adw.PreferencesPage () {
			title = _("Members"),
			icon_name = "tuba-person-symbolic"
		};
		search_group = new Adw.PreferencesGroup ();
		search_row = new Adw.EntryRow () {
			// translators: entry row title
			title = _("Search")
		};
		search_row.changed.connect (on_search_changed);
		search_group.add (search_row);

		members_group = new Adw.PreferencesGroup ();
		members_page.add (search_group);
		members_page.add (members_group);

		this.add (collection_page);
		this.add (members_page);

		update_member_metadata ();
		if (!edit_mode) this.close_attempt.connect (on_close_attempt);

		if (edit_mode) {
			cw_checkbox.toggled.connect (on_sensitive_changed);
			public_checkbox.toggled.connect (on_disc_changed);
			unlisted_checkbox.toggled.connect (on_disc_changed);

			last_cw = cw_checkbox.active;
			last_disco = public_checkbox.active;
		}

		if (edit_mode && collection.items != null && collection.items.size > 0) {
			members_page.sensitive = false;

			string[] accounts_arr = {};
			GLib.HashTable<string, string> states = new GLib.HashTable<string, string> (str_hash, str_equal);
			collection.items.foreach (e => {
				accounts_arr += @"id[]=$(e.account_id)";
				members_collection_items.set (e.account_id, e.id);
				states.insert (e.account_id, e.state);
				return true;
			});

			new Request.GET (@"/api/v1/accounts?$(string.joinv ("&", accounts_arr))")
				.with_account (accounts.active)
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					Network.parse_array (parser, node => {
						var acc = API.Account.from (node);
						add_account (acc, states.get (acc.id) == "pending");
					});
					members_page.sensitive = true;
				})
				.exec ();
		}
	}

	private void on_close_attempt () {
		if (this.edit_mode || (name_row.text.strip () == "" && members.size == 0)) {
			this.force_close ();
			return;
		}

		var dlg = new Adw.AlertDialog (
			// translators: Dialog title when closing the Collection creation dialog
			_("Create Collection?"),
			null
		);

		dlg.add_response ("cancel", _("Cancel"));
		dlg.set_response_appearance ("cancel", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("discard", _("Discard"));
		dlg.set_response_appearance ("discard", Adw.ResponseAppearance.DESTRUCTIVE);

		dlg.add_response ("create", _("Create"));
		dlg.set_response_appearance ("create", Adw.ResponseAppearance.SUGGESTED);

		dlg.default_response = "cancel";

		dlg.choose.begin (this, null, (obj, res) => {
			switch (dlg.choose.end (res)) {
				case "discard":
					this.force_close ();
					break;
				case "create":
					create_collection ();
					break;
			}
		});
	}

	private void create_collection () {
		if (this.edit_mode) return;
		this.sensitive = false;

		if (name_row.text.strip () == "") {
			this.sensitive = true;
			name_row.grab_focus ();
			// translators: error shown when creating a collection with an empty name
			this.add_toast (new Adw.Toast (_("Name cannot be empty")) {
				timeout = 10
			});
			return;
		}

		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("name");
		builder.add_string_value (name_row.text.strip ());

		if (description_row.text.strip () != "") {
			builder.set_member_name ("description");
			builder.add_string_value (description_row.text.strip ());
		}

		builder.set_member_name ("language");
		if (lang_row.selected == Gtk.INVALID_LIST_POSITION) {
			builder.add_string_value ("en");
		} else {
			var locale_obj = lang_row.selected_item as Utils.Locales.Locale;
			builder.add_string_value (locale_obj == null || locale_obj.locale == null ? "en" : locale_obj.locale);
		}

		string topic = topic_row.text.strip ();
		if (topic != "#" && topic != "") {
			builder.set_member_name ("tag_name");
			builder.add_string_value (@"$(topic.has_prefix ("#") ? "" : "#")$topic");
		}

		builder.set_member_name ("sensitive");
		builder.add_boolean_value (cw_checkbox.active);

		builder.set_member_name ("discoverable");
		builder.add_boolean_value (public_checkbox.active);

		builder.set_member_name ("account_ids");
		builder.begin_array ();
		members.foreach (e => {
			builder.add_string_value (e.key);
			return true;
		});
		builder.end_array ();

		builder.end_object ();

		new Request.POST ("/api/v1/collections")
			.with_account (accounts.active)
			.body_json (builder)
			.then ((in_stream) => {
				this.sensitive = true;
				refresh ();
				this.force_close ();
			})
			.on_error ((code, message) => {
				this.add_toast (new Adw.Toast (message) {
					timeout = 5
				});
				warning (@"Error while creating collection: $code $message");
				this.sensitive = true;
			})
			.exec ();
	}

	private void update_member_metadata () {
		// translators: collection member list title, the variables are numbers (amount of members/max amount of members)
		members_group.title = _("Members (%d/%d)").printf (members.size, MAX_MEMBERS);

		foreach (var widg in search_results) {
			widg.checkbox_active = members.has_key (widg.account.id);
			widg.checkbox_sensitive = members.size < MAX_MEMBERS || widg.checkbox_active;
		}
	}

	uint search_timeout_id = 0;
	private void on_search_changed () {
		if (search_timeout_id > 0) {
			GLib.Source.remove (search_timeout_id);
			search_timeout_id = 0;
		}
		search_timeout_id = GLib.Timeout.add (500, update_search_results);
	}

	private bool update_search_results () {
		if (search_timeout_id == 0) {
			search_timeout_id = 0;
			return GLib.Source.REMOVE;
		}
		update_search_results_real.begin (search_row.text, (obj, res) => {
			try {
				update_search_results_real.end (res);
			} catch (Error e) {
				this.add_toast (new Adw.Toast (e.message) {
					timeout = 5
				});
				warning (@"Error while searching users: $(e.code) $(e.message)");
			}
			search_timeout_id = 0;
		});
		return GLib.Source.REMOVE;
	}

	private async void update_search_results_real (string query) throws Error {
		if (search_timeout_id == 0) return;

		foreach (var widg in search_results) {
			search_group.remove (widg);
		}
		search_results = {};

		var req = API.Account.search (query.strip ());
		yield req.await ();
		if (search_results.length > 0) return;

		var parser = Network.get_parser_from_inputstream (req.response_body);
		Network.parse_array (parser, node => {
			var entity = Tuba.Helper.Entity.from_json (node, typeof (API.Account));
			if (entity is API.Account) {
				var widget = new Widgets.AccountRow ((API.Account) entity, false);
				widget.activatable = false;
				// translators: button label, clicking it invites a user to a collection
				widget.add_checkbox (_("Invite"));
				widget.checkbox_toggled.connect (on_account_toggled);
				widget.checkbox_active = members.has_key (((API.Account) entity).id);
				widget.checkbox_sensitive = members.size < MAX_MEMBERS || widget.checkbox_active;
				widget.sensitive = ((API.Account) entity).feature_approval != null && ((API.Account) entity).feature_approval.tuba_can_invite;

				search_results += widget;
				search_group.add (widget);
			}
		});
	}

	uint tag_timeout_id = 0;
	private void on_tag_search_changed () {
		if (tag_timeout_id > 0) {
			GLib.Source.remove (tag_timeout_id);
			tag_timeout_id = 0;
		}
		tag_timeout_id = GLib.Timeout.add (500, update_tag_search_results);
	}

	private bool update_tag_search_results () {
		if (tag_timeout_id == 0) {
			tag_timeout_id = 0;
			return GLib.Source.REMOVE;
		}
		update_tag_search_results_real.begin (topic_row.text.replace ("#", ""), (obj, res) => {
			try {
				update_tag_search_results_real.end (res);
			} catch (Error e) {
				this.add_toast (new Adw.Toast (e.message) {
					timeout = 5
				});
				warning (@"Error while searching tags: $(e.code) $(e.message)");
			}
			tag_timeout_id = 0;
		});
		return GLib.Source.REMOVE;
	}

	private async void update_tag_search_results_real (string query) throws Error {
		if (tag_timeout_id == 0) return;

		foreach (var widg in tag_results) {
			details_group.remove (widg);
		}
		tag_results = {};

		var req = API.Tag.search (query.strip ());
		yield req.await ();
		if (tag_results.length > 0) return;

		var parser = Network.get_parser_from_inputstream (req.response_body);
		var results = API.SearchResults.from (network.parse_node (parser));
		if (results != null) {
			results.hashtags.foreach (tag => {
				var widget = new Widgets.Tag ((API.Tag) tag);
				widget.opacity = 0.7;
				widget.activated.connect (on_tag_chosen);
				tag_results += widget;
				details_group.add (widget);
				return true;
			});
		}
	}

	private void on_tag_chosen (Adw.ActionRow tag_row) {
		topic_row.changed.disconnect (on_tag_search_changed);
		foreach (var widg in tag_results) {
			details_group.remove (widg);
		}
		tag_results = {};

		topic_row.text = ((Widgets.Tag) tag_row).name;
		topic_row.changed.connect (on_tag_search_changed);
	}

	private void on_account_toggled (Widgets.AccountRow member_row, bool new_state) {
		if (edit_mode) {
			if (new_state) {
				var builder = new Json.Builder ();
				builder.begin_object ();

				builder.set_member_name ("account_id");
				builder.add_string_value (member_row.account.id);

				builder.end_object ();
				member_row.sensitive = false;
				new Request.POST (@"/api/v1/collections/$collection_id/items")
					.with_account (accounts.active)
					.body_json (builder)
					.then ((in_stream) => {
						var parser = Network.get_parser_from_inputstream (in_stream);
						var node = network.parse_node (parser);
						API.WrappedCollectionItem ci = (API.WrappedCollectionItem) Helper.Entity.from_json (node, typeof (API.WrappedCollectionItem));

						add_account (member_row.account, ci.collection_item.state == "pending");
						members_collection_items.set (member_row.account.id, ci.collection_item.id);
						member_row.sensitive = true;
					})
					.on_error ((code, message) => {
						this.add_toast (new Adw.Toast (message) {
							timeout = 5
						});
						warning (@"Error while adding collection member: $(code) $(message)");
						member_row.sensitive = true;
						member_row.checkbox_toggled.disconnect (on_account_toggled);
						member_row.checkbox_active = false;
						member_row.checkbox_toggled.connect (on_account_toggled);
					})
					.exec ();
			} else {
				member_row.sensitive = false;
				new Request.DELETE (@"/api/v1/collections/$collection_id/items/$(members_collection_items.get (member_row.account.id))")
					.with_account (accounts.active)
					.then (() => {
						remove_account (member_row.account.id);
					})
					.on_error ((code, message) => {
						this.add_toast (new Adw.Toast (message) {
							timeout = 5
						});
						warning (@"Error while removing collection member: $(code) $(message)");
						member_row.sensitive = true;
						member_row.checkbox_toggled.disconnect (on_account_toggled);
						member_row.checkbox_active = true;
						member_row.checkbox_toggled.connect (on_account_toggled);
					})
					.exec ();
			}
		} else {
			if (new_state) {
				add_account (member_row.account);
			} else {
				remove_account (member_row.account.id);
			}
		}
	}

	private void add_account (API.Account acc, bool pending = false) {
		if (members.size >= MAX_MEMBERS || members.has_key (acc.id)) return;

		var member_row = new Widgets.AccountRow (acc, false);
		// translators: collection invitation acceptance is pending, its a badge shown next to an account
		if (pending) member_row.add (new Gtk.Label (_("Pending")) {
			css_classes = {"warning", "profile-role", "tuba-circular"},
			tooltip_text = _("Pending"),
			ellipsize = END,
			valign = Gtk.Align.CENTER
		});
		member_row.add_button (_("Remove"), "user-trash-symbolic", { "circular", "flat", "error" });
		member_row.button_clicked.connect (on_acc_row_remove_clicked);
		members.set (acc.id, member_row);

		members_group.add (member_row);
		update_member_metadata ();
	}

	private void remove_account (string acc_id) {
		if (!members.has_key (acc_id)) return;
		members_group.remove (members.get (acc_id));
		members.unset (acc_id);
		if (members_collection_items.has_key (acc_id)) members_collection_items.unset (acc_id);
		update_member_metadata ();
	}

	private void on_acc_row_remove_clicked (Widgets.AccountRow member_row) {
		if (edit_mode) {
			on_account_toggled (member_row, false);
		} else {
			remove_account (member_row.account.id);
		}
	}
}
