public class Tuba.Views.Profile : Views.Accounts {
	const int TOTAL_STATIC_ITEMS = 3;

	public class ProfileAccount : Widgetizable, GLib.Object {
		public API.Account account { get; construct set; }
		public API.Relationship rs { get; construct set; }

		public ProfileAccount (API.Account t_acc) {
			Object (account: t_acc, rs: new API.Relationship.for_account (t_acc));
		}

		public async bool update_profile () {
			Request req = new Request.GET (@"/api/v1/accounts/$(account.id)").with_account (accounts.active);

			try {
				yield req.await ();
				var parser = yield Network.get_parser_from_inputstream_async (req.response_body);
				var node = network.parse_node (parser);
				var updated = API.Account.from (node);

				account.display_name = updated.display_name;
				account.note = updated.note;
				account.locked = updated.locked;
				account.header = updated.header;
				account.header_description = updated.header_description;
				account.avatar = updated.avatar;
				account.avatar_description = updated.avatar_description;
				account.bot = updated.bot;
				account.emojis = updated.emojis;
				account.followers_count = updated.followers_count;
				account.following_count = updated.following_count;
				account.statuses_count = updated.statuses_count;
				account.fields = updated.fields;
				account.moved = updated.moved;

				return true;
			} catch (Error e) {
				warning (@"Couldn't update account $(account.id): $(e.message)");
				app.toast (e.message);
			}

			return false;
		}

		public override Gtk.Widget to_widget () {
			return new Widgets.Cover (this);
		}

		public Gtk.Widget to_mini_widget () {
			return new Widgets.Cover (this, true);
		}
	}

	public class FilterGroup : Widgetizable, GLib.Object {
		public bool visible { get; set; default=true; }

		public override Gtk.Widget to_widget () {
			var widget = new Widgets.ProfileFilterGroup ();
			this.bind_property ("visible", widget, "visible", GLib.BindingFlags.SYNC_CREATE);
			return widget;
		}
	}

	public class ErrorMessageRow : Widgetizable, GLib.Object {
		public bool visible { get; set; default=true; }
		public string message { get; set; default = ""; }

		public override Gtk.Widget to_widget () {
			var widget = new Gtk.Label (message) {
				wrap = true,
				wrap_mode = WORD_CHAR,
				css_classes = { "title-1" },
				margin_start = 16,
				margin_end = 16,
				margin_top = 16,
				margin_bottom = 16,
				justify = CENTER
			};

			var row = new Gtk.ListBoxRow () {
				child = widget,
				overflow = Gtk.Overflow.HIDDEN,
				activatable = false
			};

			this.bind_property ("visible", row, "visible", GLib.BindingFlags.SYNC_CREATE);
			this.bind_property ("message", widget, "label", GLib.BindingFlags.SYNC_CREATE);
			return row;
		}
	}

	public override bool empty {
		get { return false; }
	}

	public ProfileAccount profile { get; construct set; }
	public Widgets.ProfileFilterGroup.Filter filter { get; set; default = Widgets.ProfileFilterGroup.Filter.POSTS; }
	public string source { get; set; default = "statuses"; }
	private signal void cover_profile_update (API.Account acc);

	protected Gtk.MenuButton menu_button;
	protected SimpleAction muting_action;
	protected SimpleAction hiding_reblogs_action;
	protected SimpleAction blocking_action;
	protected SimpleAction domain_blocking_action;
	protected SimpleAction endorse_action;
	protected SimpleAction ar_list_action;
	protected SimpleAction notify_on_new_post_action;
	//  protected SimpleAction source_action;

	private FilterGroup filter_group;
	private ErrorMessageRow error_message_row = new ErrorMessageRow () {
		visible = false
	};
	public Profile (API.Account acc) {
		Object (
			profile: new ProfileAccount (acc),
			label: _("Profile"),
			allow_nesting: true,
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);

		this.bind_property ("empty-state-title", error_message_row, "message", SYNC_CREATE);
		filter_group = new FilterGroup ();
		model.insert (0, profile);
		model.insert (1, filter_group);
		model.insert (2, error_message_row);
		profile.rs.invalidated.connect (on_rs_updated);

		if (acc.is_self ()) {
			update_profile_cover ();
			app.refresh_featured.connect (on_featured_refresh_request);
		}
	}
	~Profile () {
		debug ("Destroying Profile view");
	}

	private void on_featured_refresh_request () {
		if (this.filter == FEATURED) on_refresh ();
	}

	public bool append_pinned () {
		if (source == "statuses" && filter == Widgets.ProfileFilterGroup.Filter.POSTS) {
			new Request.GET (@"/api/v1/accounts/$(profile.account.id)/statuses")
				.with_account (account)
				.with_param ("pinned", "true")
				.with_ctx (this)
				.then ((in_stream) => {
					Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
						try {
							var parser = Network.get_parser_from_inputstream_async.end (res);

							Object[] to_add = {};
							Network.parse_array (parser, node => {
								var e = Tuba.Helper.Entity.from_json (node, typeof (API.Status));
								var e_status = e as API.Status;
								if (e_status != null) e_status.pinned = true;

								to_add += e_status;
							});
							model.splice (TOTAL_STATIC_ITEMS, 0, to_add);
						} catch (Error e) {
							critical (@"Couldn't parse json: $(e.code) $(e.message)");
						}
					});
				})
				.exec ();
		}

		return GLib.Source.REMOVE;
	}

	public override void on_request_finish () {
		base.on_request_finish ();
		on_content_changed ();
	}

	private void on_cover_aria_update (Widgets.Cover p_cover, string new_aria) {
		var lbr = p_cover.get_parent ();
		if (lbr != null) {
			lbr.update_property (Gtk.AccessibleProperty.LABEL, new_aria, -1);
			lbr.update_relation (Gtk.AccessibleRelation.DESCRIBED_BY, p_cover.note, null, -1);
		}
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);

		var widget_cover = widget as Widgets.Cover;
		if (widget_cover != null) {
			widget_cover.rs_invalidated.connect (on_rs_updated);
			widget_cover.timeline_change.connect (change_timeline_source);
			widget_cover.aria_updated.connect (on_cover_aria_update);
			widget_cover.remove_css_class ("card");
			widget_cover.remove_css_class ("card-spacing");
			this.cover_profile_update.connect (widget_cover.update_cover_from_profile);

			var row = new Gtk.ListBoxRow () {
				focusable = true,
				activatable = false,
				child = widget_cover,
				css_classes = { "card-spacing", "card" },
				overflow = Gtk.Overflow.HIDDEN
			};
			widget_cover.update_aria ();

			return row;
		}

		var widget_status = widget as Widgets.Status;
		if (widget_status != null && profile.account.id == accounts.active.id) {
			widget_status.show_toggle_pinned_action ();
			widget_status.pin_changed.connect (on_refresh);
		}

		var widget_filter_group = widget as Widgets.ProfileFilterGroup;
		if (widget_filter_group != null) {
			widget_filter_group.remove_css_class ("card");
			widget_filter_group.remove_css_class ("card-spacing");
			widget_filter_group.filter_change.connect (change_filter);
		}

		if (obj is ErrorMessageRow) {
			widget.remove_css_class ("card");
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
		error_message_row.visible = false;
		base.on_refresh ();
		GLib.Idle.add (append_pinned);
		GLib.Idle.add (append_featured_tags);
	}

	public override bool request () {
		base.request ();
		return GLib.Source.REMOVE;
	}

	public override void on_manual_refresh () {
		update_profile_cover ();
		base.on_manual_refresh ();
	}

	protected void change_timeline_source (string t_source) {
		if (t_source == "statuses-like") {
			source = this.filter == FEATURED ? "endorsements" : "statuses";
		} else {
			source = t_source;
		}

		filter_group.visible = source == "statuses" || source == "endorsements";
		source_meta_update (source);

		url = @"/api/v1/accounts/$(profile.account.id)/$source";
		invalidate_actions (true);
	}

	private void source_meta_update (string t_source) {
		switch (t_source) {
			case "statuses":
				accepts = typeof (API.Status);
				// translators: posts tab on profiles, shown when empty.
				empty_state_title = _("No Posts");
				break;
			case "followers":
				accepts = typeof (API.Account);
				// translators: followers tab on profiles, shown when empty.
				empty_state_title = _("No Followers");
				break;
			case "following":
				accepts = typeof (API.Account);
				// translators: following tab on profiles, shown when empty.
				empty_state_title = _("This user doesn't follow anyone yet");
				break;
			case "endorsements":
				accepts = typeof (API.Account);
				// translators: featured tab on profiles, shown when empty.
				empty_state_title = _("This user doesn't have any featured hashtags or accounts.");
				break;
			default:
				assert_not_reached ();
		}
	}

	protected void change_filter (Widgets.ProfileFilterGroup.Filter filter) {
		bool was_featured = this.filter == FEATURED;
		this.filter = filter;
		if (this.filter == FEATURED || was_featured) {
			change_timeline_source ("statuses-like");
		} else {
			source_meta_update (source);
			invalidate_actions (true);
		}
	}

	private bool append_featured_tags () {
		if (source == "endorsements" && filter == Widgets.ProfileFilterGroup.Filter.FEATURED) {
			fill_featured.begin ((obj, res) => {
				try {
					fill_featured.end (res);
				} catch (Error e) {
					on_error (e.code, e.message);
				}
			});
		}

		return GLib.Source.REMOVE;
	}

	private async void fill_featured () throws Error {
		Object[] to_add = {};

		var req = new Request.GET (@"/api/v1/accounts/$(profile.account.id)/featured_tags")
				.with_account (account)
				.with_ctx (this);
		yield req.await ();

		var parser = yield Network.get_parser_from_inputstream_async (req.response_body);
		Network.parse_array (parser, node => {
			to_add += Tuba.Helper.Entity.from_json (node, typeof (API.FeaturedTag));
		});

		//  req = new Request.GET (@"/api/v1/accounts/$(profile.account.id)/endorsements")
		//  		.with_account (account)
		//  		.with_ctx (this);
		//  yield req.await ();

		//  parser = Network.get_parser_from_inputstream (req.response_body);
		//  Network.parse_array (parser, node => {
		//  	to_add += Tuba.Helper.Entity.from_json (node, typeof (API.Account));
		//  });
		model.splice (TOTAL_STATIC_ITEMS, 0, to_add);
	}

	public override void on_content_changed () {
		error_message_row.visible = false;
		base.on_content_changed ();
		if (has_finished_request && base_status == null && model.get_n_items () == TOTAL_STATIC_ITEMS) {
			error_message_row.visible = true;
		}
	}

	protected override void build_header () {
		base.build_header ();

		menu_button = new Gtk.MenuButton () {
			icon_name = "view-more-symbolic"
		};
		var menu_builder = new Gtk.Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		var menu = "profile-menu";
		menu_button.menu_model = menu_builder.get_object (menu) as MenuModel;
		menu_button.popover.width_request = 250;
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
		var dialog = new Dialogs.ProfileEdit (profile.account.is_self () ? accounts.active : profile.account);
		dialog.saved.connect (on_edit_save);
		dialog.present (app.main_window);
	}

	private void on_edit_save () {
		if (profile.account.is_self ()) {
			//  for (uint i = 0; i < model.get_n_items (); i++) {
			//  	var status_obj = (API.Status)model.get_item (i);
			//  	if (status_obj.formal.account.id == profile.account.id) {
			//  		Tuba.EntityCache.remove (status_obj.formal.uri);
			//  	}
			//  }

			this.cover_profile_update (accounts.active);
		}
	}

	private void update_profile_cover () {
		profile.update_profile.begin ((obj, res) => {
			if (profile.update_profile.end (res)) {
				this.cover_profile_update (profile.account);
			}
		});
	}

	protected override void clear () {
		base.clear_all_but_first (TOTAL_STATIC_ITEMS);
	}

	protected override void build_actions () {
		base.build_actions ();

		notify_on_new_post_action = new SimpleAction.stateful ("notify_on_post", null, false);
		notify_on_new_post_action.change_state.connect (v => {
			profile.rs.modify ("follow", {{"notify", v.get_boolean ().to_string ()}});
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
			create_ar_list_dialog ().present (app.main_window);
		});
		actions.add_action (ar_list_action);

		var mention_action = new SimpleAction ("mention", VariantType.STRING);
		mention_action.activate.connect (v => {
			new Dialogs.Composer.Dialog ({@"$(profile.account.handle) ", null, null, null, null, null, null, false, false}, v.get_string ());
		});
		actions.add_action (mention_action);

		var copy_handle_action = new SimpleAction ("copy_handle", null);
		copy_handle_action.activate.connect (v => {
			Utils.Host.copy (profile.account.full_handle);
			app.toast (_("Copied handle to clipboard"));
		});
		actions.add_action (copy_handle_action);

		var open_in_browser_action = new SimpleAction ("open_in_browser", null);
		open_in_browser_action.activate.connect (v => {
			#if WEBKIT
				if (settings.use_in_app_browser_if_available && Views.Browser.can_handle_url (profile.account.url)) {
					(new Views.Browser.with_url (profile.account.url)).present (app.main_window);
					return;
				}
			#endif

			Utils.Host.open_url.begin (profile.account.url);
		});
		actions.add_action (open_in_browser_action);

		var report_action = new SimpleAction ("report", null);
		report_action.activate.connect (v => {
			new Dialogs.Report (profile.account);
		});
		actions.add_action (report_action);

		muting_action = new SimpleAction.stateful ("muting", null, false);
		muting_action.change_state.connect (v => {
			var state = v.get_boolean ();
			if (state) {
				profile.rs.question_modify_mute (profile.account.handle);
			} else {
				profile.rs.modify ("unmute");
			}
		});
		actions.add_action (muting_action);

		hiding_reblogs_action = new SimpleAction.stateful ("hiding_reblogs", null, false);
		hiding_reblogs_action.change_state.connect (v => {
			if (!profile.rs.following) {
				warning ("Trying to hide boosts while not following an account.");
				return;
			}

			var state = !v.get_boolean ();
			profile.rs.modify ("follow", {{"reblogs", state.to_string ()}});
		});
		actions.add_action (hiding_reblogs_action);

		blocking_action = new SimpleAction.stateful ("blocking", null, false);
		blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			profile.rs.question_modify_block (profile.account.handle, block);
		});
		actions.add_action (blocking_action);

		domain_blocking_action = new SimpleAction.stateful ("domain_blocking", null, false);
		domain_blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block Entire \"%s\"?") : _("Unblock Entire \"%s\"?");
			app.question.begin (
				{q.printf (profile.account.domain), false},
				{_("Blocking a domain will:\n\n• Remove its public posts and notifications from your timelines\n• Remove its followers from your account\n• Prevent you from following its users"), false},

				app.main_window,
				{ { block ? _("Block") : _("Unblock"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						var req = new Request.POST ("/api/v1/domain_blocks")
							.with_account (accounts.active)
							.with_param ("domain", profile.account.domain)
							.then (() => {
								profile.rs.request ();
							});

						if (!block) req.method = "DELETE";
						req.exec ();
					}
				}
			);
		});
		actions.add_action (domain_blocking_action);

		string endorse_str = accounts.active.tuba_api_versions.mastodon >= 6 ? "endorse" : "pin";
		string unendorse_str = accounts.active.tuba_api_versions.mastodon >= 6 ? "unendorse" : "unpin";

		endorse_action = new SimpleAction.stateful ("endorsed", null, false);
		endorse_action.change_state.connect (v => {
			profile.rs.modify (v.get_boolean () ? endorse_str : unendorse_str);
			invalidate_actions (false);
		});
		actions.add_action (endorse_action);

		invalidate_actions (false);
	}

	void invalidate_actions (bool refresh) {
		muting_action.set_state (profile.rs.muting);
		endorse_action.set_state (profile.rs.endorsed);
		endorse_action.set_enabled (profile.rs.following);
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
			switch (this.filter) {
				case Widgets.ProfileFilterGroup.Filter.POSTS:
					req.with_param ("exclude_replies", "true");
					break;
				case Widgets.ProfileFilterGroup.Filter.REPLIES:
					req.with_param ("exclude_replies", "false");
					req.with_param ("exclude_reblogs", "true");
					break;
				case Widgets.ProfileFilterGroup.Filter.MEDIA:
					req.with_param ("only_media", "true");
					break;
				case Widgets.ProfileFilterGroup.Filter.FEATURED: break;
				default:
					assert_not_reached ();
			}
		}
		return base.append_params (req);
	}

	public class RowButton : Gtk.Button {
		public bool remove { get; set; default = false; }
	}

	public Adw.Dialog create_ar_list_dialog () {
		var spinner = new Adw.Spinner () {
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
		var dialog = new Adw.Dialog () {
			// translators: the variable is an account handle
			title = _("Add or remove \"%s\" to or from a list").printf (profile.account.handle),
			child = toolbar_view,
			content_width = 600,
			content_height = 550
		};

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

		// TODO: async yield these
		new Request.GET ("/api/v1/lists/")
			.with_account (accounts.active)
			.with_ctx (this)
			.on_error (on_error)
			.then ((in_stream) => {
				Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
					try {
						var parser = Network.get_parser_from_inputstream_async.end (res);
						if (Network.get_array_size (parser) > 0) {
							new Request.GET (@"/api/v1/accounts/$(profile.account.id)/lists")
								.with_account (accounts.active)
								.with_ctx (this)
								.on_error (on_error)
								.then ((in_stream2) => {
									Network.get_parser_from_inputstream_async.begin (in_stream2, (obj, res) => {
										try {
											var added = false;
											var in_list = new Gee.ArrayList<string> ();
											var parser2 = Network.get_parser_from_inputstream_async.end (res);
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
													use_markup = false,
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
										} catch (Error e) {
											critical (@"Couldn't parse json: $(e.code) $(e.message)");
										}
									});
								})
								.exec ();
						} else {
							toast_overlay.child = no_lists_page;
						}
					} catch (Error e) {
						critical (@"Couldn't parse json: $(e.code) $(e.message)");
					}
				});
			})
			.exec ();

		return dialog;
	}

	public void handle_list_edit (API.List list, Adw.ActionRow row, Adw.ToastOverlay toast_overlay, RowButton button) {
			row.sensitive = false;

			var builder = new Json.Builder ();
			builder.begin_object ();
			builder.set_member_name ("account_ids");
			builder.begin_array ();
			builder.add_string_value (profile.account.id);
			builder.end_array ();
			builder.end_object ();

			var endpoint = @"/api/v1/lists/$(list.id)/accounts";
			var req = button.remove ? new Request.DELETE (endpoint) : new Request.POST (endpoint);
			req
				.with_account (accounts.active)
				.with_ctx (this)
				.body_json (builder)
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
