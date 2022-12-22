using Gtk;

// TODO: Lists is borken
public class Tooth.Views.Lists : Views.Timeline {

    public class Row : Adw.ActionRow {
		public API.List? list;
		Button delete_button;
		Button edit_button;
		Adw.PreferencesWindow preferences_dialog;

		construct {
			var action_box = new Box(Orientation.HORIZONTAL, 6);

			edit_button = new Button() {
				icon_name = "tooth-edit-symbolic",
				valign = Align.CENTER,
				halign = Align.CENTER
			};
			edit_button.add_css_class("flat");
			edit_button.add_css_class("circular");
			edit_button.clicked.connect(() => {
				preferences_dialog.show();
			});

			delete_button = new Button() {
				icon_name = "tooth-trash-symbolic",
				valign = Align.CENTER,
				halign = Align.CENTER
			};
			delete_button.add_css_class("flat");
			delete_button.add_css_class("circular");
			delete_button.add_css_class("error");
			delete_button.clicked.connect(on_remove_clicked);

			//  this.apply.connect(on_apply);
			action_box.append(edit_button);
			action_box.append(delete_button);

			this.activated.connect(() => open());
			this.activatable = true;

			this.add_suffix(action_box);
		}

		public Row (API.List? list) {
			this.list = list;

			if (list != null) {
				list.bind_property ("title", this, "title", BindingFlags.SYNC_CREATE);
				preferences_dialog = create_edit_preferences_window(list);
			}
		}

		[GtkCallback]
		void on_edit_clicked () {
			new Dialogs.ListEditor (this.list);
		}

		public virtual signal void remove_from_model () {}

		void on_remove_clicked () {
			var remove = app.question (
				_("Delete \"%s\"?").printf (list.title),
				_("This action cannot be reverted."),
				app.main_window,
				_("Delete"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			remove.response.connect(res => {
				if (res == "yes") {
					new Request.DELETE (@"/api/v1/lists/$(list.id)")
						.with_account (accounts.active)
						.then (() => {
							remove_from_model();
							this.destroy ();
						})
						.exec ();
				}
				remove.destroy();
			});

			remove.present ();
		}

		public Adw.PreferencesWindow create_edit_preferences_window(API.List t_list) {
			var edit_preferences_window = new Adw.PreferencesWindow() {
				modal = true,
				title = _("Edit \"%s\"").printf (t_list.title),
				transient_for = app.main_window
			};
			var list_settings_page_general = new Adw.PreferencesPage() {
				icon_name = "tooth-gear-symbolic",
				title = _("General")
			};
			var info_group = new Adw.PreferencesGroup() {
				title = _("Info")
			};
			var title_row = new Adw.EntryRow() {
				input_purpose = InputPurpose.FREE_FORM,
				title = _("List Name"),
				text = t_list.title
			};
			info_group.add(title_row);
			list_settings_page_general.add(info_group);

			if (t_list.replies_policy != null) {
				var replies_group = new Adw.PreferencesGroup() {
					title = _("Replies Policy"),
					description = _("Show member replies to")
				};
				var none_radio = new CheckButton();
				var none_row = new Adw.ActionRow() {
					title = _("Nobody"),
					activatable_widget = none_radio
				};
				none_row.add_prefix(none_radio);

				var list_radio = new CheckButton();
				list_radio.group = none_radio;
				var list_row = new Adw.ActionRow() {
					title = _("Other members of the list"),
					activatable_widget = list_radio
				};
				list_row.add_prefix(list_radio);

				var followed_radio = new CheckButton();
				followed_radio.group = none_radio;
				var followed_row = new Adw.ActionRow() {
					title = _("Any followed user"),
					activatable_widget = followed_radio
				};
				followed_row.add_prefix(followed_radio);

				switch (t_list.replies_policy) {
					case "none":
						none_radio.active = true;
						break;
					case "followed":
						followed_radio.active = true;
						break;
					default:
						list_radio.active = true;
						break;
				}

				replies_group.add(none_row);
				replies_group.add(list_row);
				replies_group.add(followed_row);

				list_settings_page_general.add(replies_group);
			}

			var to_remove = new Gee.ArrayList<string>();
			new Request.GET (@"/api/v1/lists/$(t_list.id)/accounts")
				.with_account (accounts.active)
				.then ((sess, msg) => {
					if (Network.get_array_size(msg) > 0) {
						var list_settings_page_members = new Adw.PreferencesPage() {
							icon_name = "tooth-people-symbolic",
							title = _("Members")
						};

						var rm_group = new Adw.PreferencesGroup() {
							title = _("Remove Members")
						};

						Network.parse_array (msg, node => {
							var member = API.Account.from (node);
							var avi = new Widgets.Avatar() {
								account = member,
								size = 32
							};
							var m_switch = new Switch() {
								active = true,
								state = true,
								valign = Align.CENTER,
								halign = Align.CENTER
							};
							m_switch.state_set.connect((x) => {
								if (!x) {
									to_remove.add(member.id);
								} else if (to_remove.contains(member.id)) {
									to_remove.remove(member.id);
								}

								return x;
							});

							var member_row = new Adw.ActionRow() {
								title = member.full_handle
							};
							member_row.add_prefix(avi);
							member_row.add_suffix(m_switch);

							rm_group.add(member_row);
						});

						list_settings_page_members.add(rm_group);
						edit_preferences_window.add(list_settings_page_members);
					}
				})
				.exec();

			edit_preferences_window.add(list_settings_page_general);

			return edit_preferences_window;
		}

		//  public void on_apply() {
		//  	if (entry.text_length == 0) return;

		//  	new Request.PUT (@"/api/v1/lists/$(list.id)")
		//  		.with_account (accounts.active)
		//  		.with_param ("title", entry.buffer.text)
		//  		.then (() => {
		//  			this.title = entry.buffer.text;
		//  			entry.buffer.set_text("".data);
		//  		})
		//  		.exec ();
		//  }

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

	public override Widget on_create_model_widget(Object obj) {
		var widget = base.on_create_model_widget(obj);
		var widget_row = widget as Row;

		if (widget_row != null)
			widget_row.remove_from_model.connect(() => remove_list(widget_row.list));

		return widget;
	}

	public void remove_list(API.List? list) {
		if (list == null) return;

		uint indx;
		var found = model.find (list, out indx);
		if (found)
			model.remove(indx);
	}

    public Lists () {
        Object (
        	url: @"/api/v1/lists",
            label: _("Lists"),
            icon: "tooth-list-compact-symbolic"
        );
        accepts = typeof (API.List);
    }

	public void create_list(string list_name) {
		new Request.POST ("/api/v1/lists")
			.with_account (accounts.active)
			.with_param ("title", list_name)
			.then ((sess, msg) => {
				var node = network.parse_node (msg);
				var list = API.List.from (node);
				model.insert (0, list);
			})
			.exec ();
	}

	public void on_action_bar_activate(EntryBuffer buffer) {
		if (buffer.length > 0)
				create_list(buffer.text);
		buffer.set_text("".data);
	}

	construct {
        var add_action_bar = new ActionBar ();
		add_action_bar.add_css_class("ttl-box-no-shadow");

		var child_box = new Box(Orientation.HORIZONTAL, 6);
		var child_entry = new Entry() {
			input_purpose = InputPurpose.FREE_FORM,
			placeholder_text = _("New list title")
		};
		var add_button = new Button.with_label (_("Add list")) {
			sensitive = false
		};

		add_button.clicked.connect(() => {
			on_action_bar_activate(child_entry.buffer);
		});
		child_entry.activate.connect(() => {
			on_action_bar_activate(child_entry.buffer);
		});

		child_entry.buffer.bind_property("length", add_button, "sensitive", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_boolean ((uint) src > 0);
			return true;
		});

		child_box.append(child_entry);
		child_box.append(add_button);

		add_action_bar.set_center_widget(child_box);
		insert_child_after (add_action_bar, header);
	}
	
    public override void on_request_finish () {
		on_content_changed ();
    }

}
