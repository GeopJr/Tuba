public class Tuba.Views.Lists : Views.Timeline {

    public class Row : Adw.ActionRow {
		public API.List? list;
		Gtk.Button delete_button;
		Gtk.Button edit_button;

		construct {
			var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

			edit_button = new Gtk.Button () {
				icon_name = "document-edit-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular" }
			};

			delete_button = new Gtk.Button () {
				icon_name = "tuba-trash-symbolic",
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular", "error" }
			};

			delete_button.clicked.connect (on_remove_clicked);

			//  this.apply.connect(on_apply);
			action_box.append (edit_button);
			action_box.append (delete_button);

			this.activated.connect (() => open ());
			this.activatable = true;

			this.add_suffix (action_box);
		}

		public Row (API.List? list) {
			this.list = list;

			if (list != null) {
				this.list.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
					target.set_string (GLib.Markup.escape_text (src.get_string ()));
					return true;
				});
				edit_button.clicked.connect (() => {
					create_edit_preferences_window (this.list).show ();
				});
			}
		}

		public virtual signal void remove_from_model (API.List? t_list);

		void on_remove_clicked () {
			var remove = app.question (
				_("Delete \"%s\"?").printf (this.list.title),
				_("This action cannot be reverted."),
				app.main_window,
				_("Delete"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			remove.response.connect (res => {
				if (res == "yes") {
					new Request.DELETE (@"/api/v1/lists/$(list.id)")
						.with_account (accounts.active)
						.then (() => {
							remove_from_model (this.list);
							this.destroy ();
						})
						.exec ();
				}
				remove.destroy ();
			});

			remove.present ();
		}

		public Adw.PreferencesWindow create_edit_preferences_window (API.List t_list) {
			return new Dialogs.ListEdit (t_list) {
				transient_for = app.main_window
			};
		}

		public virtual signal void open () {
			if (this.list == null)
				return;

			var view = new Views.List (list);
			app.main_window.open_view (view);
		}
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
		new Request.POST ("/api/v1/lists")
			.with_account (accounts.active)
			.with_param ("title", list_name)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var list = API.List.from (node);
				model.insert (0, list);
			})
			.exec ();
	}

	public void on_action_bar_activate (Gtk.EntryBuffer buffer) {
		if (buffer.length > 0)
				create_list (buffer.text);
		buffer.set_text ("".data);
	}

	Gtk.Entry child_entry = new Gtk.Entry () {
		input_purpose = Gtk.InputPurpose.FREE_FORM,
		placeholder_text = _("New list title")
	};

	construct {
		url = "/api/v1/lists";
        label = _("Lists");
        icon = "tuba-list-compact-symbolic";
        accepts = typeof (API.List);

        var add_action_bar = new Gtk.ActionBar () {
			css_classes = { "ttl-box-no-shadow" }
		};

		var child_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);

		var add_button = new Gtk.Button.with_label (_("Add list")) {
			sensitive = false
		};

		add_button.clicked.connect (() => {
			on_action_bar_activate (child_entry.buffer);
		});
		child_entry.activate.connect (() => {
			on_action_bar_activate (child_entry.buffer);
		});

		child_entry.buffer.bind_property (
			"length",
			add_button,
			"sensitive",
			BindingFlags.SYNC_CREATE,
			(b, src, ref target) => {
				target.set_boolean ((uint) src > 0);
				return true;
			}
		);

		child_box.append (child_entry);
		child_box.append (add_button);

		add_action_bar.set_center_widget (child_box);
		insert_child_after (add_action_bar, header);
	}

	~Lists () {
		message ("Destroying Lists view");
	}

    public override void on_request_finish () {
		base.on_request_finish ();
		on_content_changed ();
    }

}
