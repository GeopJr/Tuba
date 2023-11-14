public class Tuba.Views.Profile : Views.Timeline {
	public class ProfileAccount : Widgetizable, GLib.Object {
		public API.Account account { get; construct set; }
		public API.Relationship rs { get; construct set; }

		public ProfileAccount (API.Account t_acc) {
			Object (account: t_acc, rs: new API.Relationship.for_account (t_acc));
		}

		public override Gtk.Widget to_widget () {
			return new Widgets.Cover (this);
		}
	}

	public ProfileAccount profile { get; construct set; }
	public bool include_replies { get; set; default = false; }
	public bool only_media { get; set; default = false; }
	public string source { get; set; default = "statuses"; }

	protected Gtk.MenuButton menu_button;
	protected SimpleAction media_action;
	protected SimpleAction replies_action;
	protected SimpleAction muting_action;
	protected SimpleAction hiding_reblogs_action;
	protected SimpleAction blocking_action;
	protected SimpleAction domain_blocking_action;
	protected SimpleAction ar_list_action;
	protected SimpleAction notify_on_new_post_action;
	//  protected SimpleAction source_action;

	public Profile (API.Account acc) {
		Object (
			profile: new ProfileAccount (acc),
			label: _("Profile"),
			allow_nesting: true,
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);

		model.insert (0, profile);
		profile.rs.invalidated.connect (on_rs_updated);
	}
	~Profile () {
		debug ("Destroying Profile view");
	}

	public bool append_pinned () {
		if (source == "statuses") {
			new Request.GET (@"/api/v1/accounts/$(profile.account.id)/statuses")
				.with_account (account)
				.with_param ("pinned", "true")
				.with_ctx (this)
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);

					Object[] to_add = {};
					Network.parse_array (parser, node => {
						var e = Tuba.Helper.Entity.from_json (node, typeof (API.Status));
						var e_status = e as API.Status;
						if (e_status != null) e_status.pinned = true;

						to_add += e_status;
					});
					model.splice (1, 0, to_add);

				})
				.exec ();
		}

		return GLib.Source.REMOVE;
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);

		var widget_cover = widget as Widgets.Cover;
		if (widget_cover != null) {
			widget_cover.rs_invalidated.connect (on_rs_updated);
			widget_cover.timeline_change.connect (change_timeline_source);
			widget_cover.remove_css_class ("card");
			widget_cover.remove_css_class ("card-spacing");

			return new Gtk.ListBoxRow () {
				focusable = true,
				activatable = false,
				child = widget_cover,
				css_classes = { "card-spacing", "card" },
				overflow = Gtk.Overflow.HIDDEN
			};
		}

		var widget_status = widget as Widgets.Status;
		if (widget_status != null && profile.account.id == accounts.active.id) {
			widget_status.show_toggle_pinned_action ();
            widget_status.pin_changed.connect (on_refresh);
        }

		return widget;
	}

	#if USE_LISTVIEW
		protected override void bind_listitem_cb (GLib.Object item) {
			base.bind_listitem_cb (item);

			if (((((Gtk.ListItem) item).item) as ProfileAccount) != null)
				((Gtk.ListItem) item).activatable = false;
		}
	#endif

	public override void on_refresh () {
		base.on_refresh ();
		GLib.Idle.add (append_pinned);
	}

	protected void change_timeline_source (string t_source) {
		source = t_source;
		accepts = t_source == "statuses" ? typeof (API.Status) : typeof (API.Account);

		url = @"/api/v1/accounts/$(profile.account.id)/$t_source";
		invalidate_actions (true);
	}

	protected override void build_header () {
		base.build_header ();

		menu_button = new Gtk.MenuButton ();
		var menu_builder = new Gtk.Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		var menu = "profile-menu";
		menu_button.menu_model = menu_builder.get_object (menu) as MenuModel;
		menu_button.popover.width_request = 250;
		menu_button.icon_name = "view-more-symbolic";
		header.pack_end (menu_button);

		if (profile.account.is_self ()) {
			var edit_btn = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
				tooltip_text = _("Edit Profile")
			};
			edit_btn.clicked.connect (open_edit_page);
			header.pack_end (edit_btn);
		}

		//  rs_button = new Widgets.RelationshipButton () {
		//  	rs = this.rs
		//  };
	}

	private void open_edit_page () {
		var dialog = new Dialogs.ProfileEdit (profile.account);
		dialog.saved.connect (on_edit_save);
		dialog.show ();
	}

	private void on_edit_save () {
		if (profile.account.is_self ()) {
			model.remove (0);

			//  for (uint i = 0; i < model.get_n_items (); i++) {
			//  	var status_obj = (API.Status)model.get_item (i);
			//  	if (status_obj.formal.account.id == profile.account.id) {
			//  		Tuba.EntityCache.remove (status_obj.formal.uri);
			//  	}
			//  }

			model.insert (0, new ProfileAccount (accounts.active));
			on_refresh ();
		}
	}

	protected override void clear () {
		base.clear_all_but_first ();
	}

	protected override void build_actions () {
		base.build_actions ();

		media_action = new SimpleAction.stateful ("only-media", null, false);
		media_action.change_state.connect (v => {
			media_action.set_state (only_media = v.get_boolean ());
			invalidate_actions (true);
		});
		actions.add_action (media_action);

		replies_action = new SimpleAction.stateful ("include-replies", null, false);
		replies_action.change_state.connect (v => {
			replies_action.set_state (include_replies = v.get_boolean ());
			invalidate_actions (true);
		});
		actions.add_action (replies_action);

		notify_on_new_post_action = new SimpleAction.stateful ("notify_on_post", null, false);
		notify_on_new_post_action.change_state.connect (v => {
			profile.rs.modify ("follow", "notify", v.get_boolean ().to_string ());
			invalidate_actions (false);
		});
		actions.add_action (notify_on_new_post_action);

		//  source_action = new SimpleAction.stateful ("source", VariantType.STRING, source);
		//  source_action.change_state.connect (v => {
		//  	source = v.get_string ();
		//  	source_action.set_state (source);
		//  	accepts = (source == "statuses" ? typeof (API.Status) : typeof (API.Account));

		//  	url = @"/api/v1/accounts/$(profile.account.id)/$source";
		//  	invalidate_actions (true);
		//  });
		//  actions.add_action (source_action);
		ar_list_action = new SimpleAction ("ar_list", null);
		ar_list_action.activate.connect (v => {
			create_ar_list_dialog ().show ();
		});
		actions.add_action (ar_list_action);

		var mention_action = new SimpleAction ("mention", VariantType.STRING);
		mention_action.activate.connect (v => {
			var status = new API.Status.empty ();
			status.visibility = v.get_string ();
			status.content = @"$(profile.account.handle) ";
			new Dialogs.Compose (status);
		});
		actions.add_action (mention_action);

		var copy_handle_action = new SimpleAction ("copy_handle", null);
		copy_handle_action.activate.connect (v => {
			Host.copy (profile.account.full_handle);
			app.toast (_("Copied handle to clipboard"));
		});
		actions.add_action (copy_handle_action);

		var open_in_browser_action = new SimpleAction ("open_in_browser", null);
		open_in_browser_action.activate.connect (v => {
			Host.open_uri (profile.account.url);
		});
		actions.add_action (open_in_browser_action);

		muting_action = new SimpleAction.stateful ("muting", null, false);
		muting_action.change_state.connect (v => {
			var state = v.get_boolean ();
			profile.rs.modify (state ? "mute" : "unmute");
		});
		actions.add_action (muting_action);

		hiding_reblogs_action = new SimpleAction.stateful ("hiding_reblogs", null, false);
		hiding_reblogs_action.change_state.connect (v => {
			if (!profile.rs.following) {
				warning ("Trying to hide boosts while not following an account.");
				return;
			}

			var state = !v.get_boolean ();
			profile.rs.modify ("follow", "reblogs", state.to_string ());
		});
		actions.add_action (hiding_reblogs_action);

		blocking_action = new SimpleAction.stateful ("blocking", null, false);
		blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block \"%s\"?") : _("Unblock \"%s\"?");

			var confirmed = app.question (
				q.printf (profile.account.handle),
				null,
				app.main_window,
				block ? _("Block") : _("Unblock"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect (res => {
				if (res == "yes") {
					profile.rs.modify (block ? "block" : "unblock");
				}
				confirmed.destroy ();
			});

			confirmed.present ();
		});
		actions.add_action (blocking_action);

		domain_blocking_action = new SimpleAction.stateful ("domain_blocking", null, false);
		domain_blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block Entire \"%s\"?") : _("Unblock Entire \"%s\"?");
			warning (q);
			var confirmed = app.question (
				q.printf (profile.account.domain),
				_("Blocking a domain will:\n\n• Remove its public posts and notifications from your timelines\n• Remove its followers from your account\n• Prevent you from following its users"), // vala-lint=line-length

				app.main_window,
				block ? _("Block") : _("Unblock"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect (res => {
				if (res == "yes") {
					var req = new Request.POST ("/api/v1/domain_blocks")
					.with_account (accounts.active)
					.with_param ("domain", profile.account.domain)
					.then (() => {
						profile.rs.request ();
					});

				if (!block) req.method = "DELETE";
				req.exec ();
				}
				confirmed.destroy ();
			});

			confirmed.present ();
		});
		actions.add_action (domain_blocking_action);

		invalidate_actions (false);
	}

	void invalidate_actions (bool refresh) {
		replies_action.set_enabled (accepts == typeof (API.Status));
		media_action.set_enabled (accepts == typeof (API.Status));
		muting_action.set_state (profile.rs.muting);
		hiding_reblogs_action.set_state (!profile.rs.showing_reblogs);
		hiding_reblogs_action.set_enabled (profile.rs.following);
		blocking_action.set_state (profile.rs.blocking);
		domain_blocking_action.set_state (profile.rs.domain_blocking);
		domain_blocking_action.set_enabled (accounts.active.domain != profile.account.domain);
		ar_list_action.set_enabled (profile.account.id != accounts.active.id && profile.rs.following);
		notify_on_new_post_action.set_enabled (profile.account.id != accounts.active.id && profile.rs.following);
		notify_on_new_post_action.set_state (profile.rs.notifying);

		if (refresh) {
			page_next = null;
			on_refresh ();
		}
	}

	void on_rs_updated () {
		invalidate_actions (false);
	}

	public override Request append_params (Request req) {
		if (page_next == null && source == "statuses") {
			req.with_param ("exclude_replies", (!include_replies).to_string ());
			req.with_param ("only_media", only_media.to_string ());
		}
		return base.append_params (req);
	}

	public static void open_from_id (string id) {
		var msg = new Soup.Message ("GET", @"$(accounts.active.instance)/api/v1/accounts/$id");
		network.queue (msg, null, (in_stream) => {
			var parser = Network.get_parser_from_inputstream (in_stream);
			var node = network.parse_node (parser);
			var acc = API.Account.from (node);
			app.main_window.open_view (new Views.Profile (acc));
		},
		network.on_error);
	}

	public class RowButton : Gtk.Button {
		public bool remove { get; set; default = false; }
	}

	public Adw.Window create_ar_list_dialog () {
		var spinner = new Gtk.Spinner () {
			spinning = true,
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			vexpand = true,
			hexpand = true,
			width_request = 32,
			height_request = 32
		};
		var toolbar_view = new Adw.ToolbarView ();
		var headerbar = new Adw.HeaderBar ();
		var toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		toast_overlay.child = spinner;

		toolbar_view.add_top_bar (headerbar);
		toolbar_view.set_content (toast_overlay);
		var dialog = new Adw.Window () {
			// translators: the variable is an account handle
			title = _("Add or remove \"%s\" to or from a list").printf (profile.account.handle),
			modal = true,
			transient_for = app.main_window,
			content = toolbar_view,
			default_width = 600,
			default_height = 550
		};
		spinner.start ();

		var preferences_page = new Adw.PreferencesPage ();
		var preferences_group = new Adw.PreferencesGroup () {
			title = _("Lists"),
			// translators: the variable is an account handle
			description = _("Select the list to add or remove \"%s\" to or from:").printf (profile.account.handle)
		};

		var no_lists_page = new Adw.StatusPage () {
			icon_name = "dialog-error-symbolic",
			vexpand = true,
			title = _("You don't have any lists")
		};

		new Request.GET ("/api/v1/lists/")
			.with_account (accounts.active)
			.with_ctx (this)
			.on_error (on_error)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				if (Network.get_array_size (parser) > 0) {
					new Request.GET (@"/api/v1/accounts/$(profile.account.id)/lists")
					.with_account (accounts.active)
					.with_ctx (this)
					.on_error (on_error)
					.then ((in_stream2) => {
						var added = false;
						var in_list = new Gee.ArrayList<string> ();

						var parser2 = Network.get_parser_from_inputstream (in_stream2);
						Network.parse_array (parser2, node => {
							var list = API.List.from (node);
							in_list.add (list.id);
						});
						Network.parse_array (parser, node => {
							var list = API.List.from (node);
							var is_already = in_list.contains (list.id);

							var add_button = new RowButton () {
								icon_name = is_already ? "tuba-minus-large-symbolic" : "tuba-plus-large-symbolic",
								tooltip_text = is_already
									? _("Remove \"%s\" from \"%s\"").printf (profile.account.handle, list.title)
									: _("Add \"%s\" to \"%s\"").printf (profile.account.handle, list.title),
								halign = Gtk.Align.CENTER,
								valign = Gtk.Align.CENTER,
								css_classes = { "flat", "circular" }
							};
							add_button.remove = is_already;

							var row = new Adw.ActionRow () {
								title = list.title
							};
							row.add_suffix (add_button);

							add_button.clicked.connect (() => {
								handle_list_edit (list, row, toast_overlay, add_button);
							});

							preferences_group.add (row);
							added = true;
						});

						if (added) {
							preferences_page.add (preferences_group);

							toast_overlay.child = preferences_page;
							toast_overlay.valign = Gtk.Align.FILL;
						} else {
							toast_overlay.child = no_lists_page;
						}
					})
					.exec ();
				} else {
					toast_overlay.child = no_lists_page;
				}
			})
			.exec ();

		return dialog;
	}

	public void handle_list_edit (API.List list, Adw.ActionRow row, Adw.ToastOverlay toast_overlay, RowButton button) {
			row.sensitive = false;

			var endpoint = @"/api/v1/lists/$(list.id)/accounts/?account_ids[]=$(profile.account.id)";
			var req = button.remove ? new Request.DELETE (endpoint) : new Request.POST (endpoint);
			req
				.with_account (accounts.active)
				.with_ctx (this)
				.on_error (on_error)
				.then (() => {
					var toast_msg = "";
					if (button.remove) {
						//  translators: First variable is a handle, second variable is a list name
						toast_msg = _("User \"%s\" got removed from \"%s\"").printf (profile.account.handle, list.title);
						button.icon_name = "tuba-plus-large-symbolic";
						//  translators: First variable is a handle, second variable is a list name
						button.tooltip_text = _("Add \"%s\" to \"%s\"").printf (profile.account.handle, list.title);
					} else {
						//  translators: First variable is a handle, second variable is a list name
						toast_msg = _("User \"%s\" got added to \"%s\"").printf (profile.account.handle, list.title);
						button.icon_name = "tuba-minus-large-symbolic";
						//  translators: First variable is a handle, second variable is a list name
						button.tooltip_text = _("Remove \"%s\" from \"%s\"").printf (profile.account.handle, list.title);
					}

					button.remove = !button.remove;
					row.sensitive = true;

					var toast = new Adw.Toast (toast_msg);
					toast_overlay.add_toast (toast);
				})
				.exec ();
	}
}
