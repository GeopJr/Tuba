public class Tuba.Views.Lists : Views.Timeline {

	public class Row : Adw.ActionRow {
		public API.List? list;
		Gtk.Button edit_button;
		Widgets.StatusActionButton fav_button;

		construct {
			var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

			edit_button = new Gtk.Button () {
				icon_name = "document-edit-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular" },
				tooltip_text = _("Edit")
			};

			var delete_button = new Gtk.Button () {
				icon_name = "user-trash-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular", "error" },
				tooltip_text = _("Delete")
			};

			delete_button.clicked.connect (on_remove_clicked);

			//  this.apply.connect(on_apply);
			action_box.append (edit_button);
			action_box.append (delete_button);

			#if !USE_LISTVIEW
				this.activated.connect (() => open ());
			#endif

			this.activatable = true;
			this.add_suffix (action_box);

			fav_button = new Widgets.StatusActionButton.with_icon_name ("tuba-unstarred-symbolic") {
				active_icon_name = "tuba-starred-symbolic",
				css_classes = { "ttl-status-action-star", "flat", "circular" },
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				tooltip_text = _("Favorite"),
			};
			fav_button.clicked.connect (on_favorite_button_clicked);
			this.add_prefix (fav_button);

			settings.notify["favorite-lists-ids"].connect (on_fav_list_updated);
		}

		private void on_fav_list_updated () {
			fav_button.sensitive = fav_button.active || settings.favorite_lists_ids.length < Views.Sidebar.MAX_SIDEBAR_LISTS;
		}

		public Row (API.List? list) {
			this.list = list;

			if (list != null) {
				this.title = GLib.Markup.escape_text (this.list.title);
				this.list.notify["id"].connect (update_fav_status);
				this.list.notify["title"].connect (title_changed);

				edit_button.clicked.connect (on_edit);
				update_fav_status ();
			}
		}

		private void title_changed () {
			this.title = GLib.Markup.escape_text (this.list.title);
			GLib.Idle.add (accounts.active.gather_fav_lists);
		}

		private void update_fav_status () {
			fav_button.active = this.list.id in settings.favorite_lists_ids;
			on_fav_list_updated ();
		}

		private void on_favorite_button_clicked () {
			fav_button.active = !fav_button.active;

			if (fav_button.active) {
				add_to_favs ();
			} else {
				remove_from_favs ();
			}
		}

		private void add_to_favs () {
			string[] new_ids = {};

			new_ids = settings.favorite_lists_ids;
			new_ids += this.list.id;

			settings.favorite_lists_ids = new_ids;

			GLib.Idle.add (accounts.active.gather_fav_lists);
		}

		private void remove_from_favs () {
			string[] new_ids = {};

			foreach (string list_id in settings.favorite_lists_ids) {
				if (this.list.id != list_id) new_ids += list_id;
			}

			settings.favorite_lists_ids = new_ids;

			GLib.Idle.add (accounts.active.gather_fav_lists);
		}

		private void on_edit () {
			create_edit_preferences_dialog (this.list).present (app.main_window);
		}

		public virtual signal void remove_from_model (API.List? t_list);

		void on_remove_clicked () {
			app.question.begin (
				{_("Delete \"%s\"?").printf (this.list.title), false},
				{_("This action cannot be reverted."), false},
				app.main_window,
				{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						new Request.DELETE (@"/api/v1/lists/$(list.id)")
							.with_account (accounts.active)
							.then (() => {
								remove_from_model (this.list);
								if (fav_button.active) remove_from_favs ();
								this.destroy ();
							})
							.exec ();
					}
				}
			);
		}

		public Adw.PreferencesDialog create_edit_preferences_dialog (API.List t_list) {
			return new Dialogs.ListEdit (t_list);
		}

		#if !USE_LISTVIEW
			public virtual signal void open () {
				if (this.list == null)
					return;

				var view = new Views.List (list);
				app.main_window.open_view (view);
			}
		#endif
	}

	public new bool empty {
		get { return false; }
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_row = widget as Row;

		if (widget_row != null)
			widget_row.remove_from_model.connect (remove_list);

		return widget;
	}

	public void remove_list (API.List? list) {
		if (list == null) return;

		uint indx;
		var found = model.find (list, out indx);
		if (found)
			model.remove (indx);
	}

	public void create_list (string list_name) {
		var builder = new Json.Builder ();
		builder.begin_object ();
		builder.set_member_name ("title");
		builder.add_string_value (list_name);
		builder.end_object ();

		new Request.POST ("/api/v1/lists")
			.with_account (accounts.active)
			.body_json (builder)
			.then ((in_stream) => {
				Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
					try {
						var parser = Network.get_parser_from_inputstream_async.end (res);
						var node = network.parse_node (parser);
						var list = API.List.from (node);
						model.insert (0, list);
					} catch (Error e) {
						critical (@"Couldn't parse json: $(e.code) $(e.message)");
					}
				});
			})
			.exec ();
	}

	public void on_action_bar_activate (Gtk.EntryBuffer buffer) {
		if (buffer.length > 0)
				create_list (buffer.text);
		buffer.set_text ("".data);
	}

	Gtk.Entry child_entry;
	Gtk.Button add_button;
	construct {
		url = "/api/v1/lists";
		label = _("Lists");
		icon = "tuba-list-compact-symbolic";
		accepts = typeof (API.List);
		empty_state_title = _("No Lists");

		child_entry = new Gtk.Entry () {
			input_purpose = Gtk.InputPurpose.FREE_FORM,
			placeholder_text = _("New list title")
		};

		var add_action_bar = new Gtk.ActionBar () {
			css_classes = { "ttl-box-no-shadow" }
		};

		var child_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

		add_button = new Gtk.Button.with_label (_("Add list")) {
			sensitive = false
		};

		add_button.clicked.connect (new_item_cb);
		child_entry.activate.connect (new_item_cb);
		child_entry.notify["text"].connect (on_entry_changed);

		child_box.append (child_entry);
		child_box.append (add_button);

		add_action_bar.set_center_widget (child_box);
		toolbar_view.add_top_bar (add_action_bar);
	}

	void new_item_cb () {
		on_action_bar_activate (child_entry.buffer);
	}

	void on_entry_changed () {
		add_button.sensitive = child_entry.text.length > 0;
	}

	~Lists () {
		debug ("Destroying Lists view");
	}

	public override void on_request_finish () {
		base.on_request_finish ();
		on_content_changed ();
	}

}
