public class Tuba.Views.Profile : Views.Timeline {
	public API.Account profile { get; construct set; }
	public API.Relationship rs { get; construct set; }
	public bool include_replies { get; set; default = false; }
	public bool only_media { get; set; default = false; }
	public string source { get; set; default = "statuses"; }

	protected Cover cover;
	protected Gtk.MenuButton menu_button;

	protected SimpleAction media_action;
	protected SimpleAction replies_action;
	protected SimpleAction muting_action;
	protected SimpleAction hiding_reblogs_action;
	protected SimpleAction blocking_action;
	protected SimpleAction domain_blocking_action;
	protected SimpleAction ar_list_action;
	//  protected SimpleAction source_action;

	construct {
		cover = build_cover ();
		cover.rsbtn.rs = this.rs;
		column_view.prepend (cover);
	}

	public Profile (API.Account acc) {
		Object (
			profile: acc,
			rs: new API.Relationship.for_account (acc),
			label: _("Profile"),
			allow_nesting: true,
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);
		cover.bind (profile);
		build_profile_stats (cover.info);
		rs.invalidated.connect (on_rs_updated);
	}
	~Profile () {
		message ("Destroying Profile view");
	}

	public bool append_pinned () {
		if (source == "statuses") {
			new Request.GET (@"/api/v1/accounts/$(profile.id)/statuses")
				.with_account (account)
				.with_param ("pinned", "true")
				.with_ctx (this)
				.then ((sess, msg, in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);

					Object[] to_add = {};
					Network.parse_array (msg, parser, node => {
						var e = entity_cache.lookup_or_insert (node, typeof (API.Status));
						var e_status = e as API.Status;
						if (e_status != null) e_status.pinned = true;

						to_add += e_status;
					});
					model.splice (0, 0, to_add);

				})
				.exec ();
		}

		return GLib.Source.REMOVE;
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_status = widget as Widgets.Status;

		if (widget_status != null && profile.id == accounts.active.id) {
			widget_status.show_toggle_pinned_action ();
            widget_status.pin_changed.connect (on_refresh);
        }

		return widget;
	}

	public override void on_refresh () {
		base.on_refresh ();
		GLib.Idle.add (append_pinned);
	}

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/profile_header.ui")]
	protected class Cover : Gtk.Box {

		[GtkChild] unowned Widgets.Background background;
		[GtkChild] unowned Gtk.Label cover_badge;
		[GtkChild] unowned Gtk.Image cover_bot_badge;
		[GtkChild] unowned Gtk.Box cover_badge_box;
		[GtkChild] public unowned Gtk.ListBox info;
		[GtkChild] unowned Widgets.EmojiLabel display_name;
		[GtkChild] unowned Gtk.Label handle;
		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Widgets.MarkupView note;
		[GtkChild] public unowned Widgets.RelationshipButton rsbtn;

		~Cover () {
			message ("Destroying Profile Cover");
		}

		construct {
			if (settings.scale_emoji_hover)
				note.add_css_class ("lww-scale-emoji-hover");
			settings.notify["scale-emoji-hover"].connect (toggle_scale_emoji_hover);
		}

		void toggle_scale_emoji_hover () {
			Tuba.toggle_css (note, settings.scale_emoji_hover, "lww-scale-emoji-hover");
		}

		public string cover_badge_label {
			get {
				return cover_badge.label;
			}

			set {
				var has_label = value != "";
				cover_badge.visible = has_label;
				cover_badge.label = value;

				update_cover_badge ();
			}
		}

		public bool is_bot {
			get {
				return cover_bot_badge.visible;
			}

			set {
				cover_bot_badge.visible = value;

				update_cover_badge ();
			}
		}

		private void update_cover_badge () {
			cover_badge_box.visible = cover_badge.visible || is_bot;

			if (is_bot && !cover_badge.visible) {
				cover_badge_box.add_css_class ("only-icon");
			} else {
				cover_badge_box.remove_css_class ("only-icon");
			}
		}

		private string avi_url { get; set; default=""; }
		private string header_url { get; set; default=""; }
		void open_header_in_media_viewer () {
			app.main_window.show_media_viewer_single (header_url, background.paintable);
		}

		void open_pfp_in_media_viewer () {
			app.main_window.show_media_viewer_single (avi_url, avatar.custom_image);
		}

		public void bind (API.Account account) {
			display_name.instance_emojis = account.emojis_map;
			display_name.content = account.display_name;
			handle.label = account.handle;
			avatar.account = account;
			note.instance_emojis = account.emojis_map;
			note.content = account.note;
			cover_bot_badge.visible = account.bot;
			update_cover_badge ();

			if (account.id != accounts.active.id) rsbtn.visible = true;

			if (account.header.contains ("/headers/original/missing.png")) {
				header_url = "";
				background.paintable = avatar.custom_image;
			} else {
				header_url = account.header ?? "";
				image_cache.request_paintable (account.header, on_cache_response);
				background.clicked.connect (open_header_in_media_viewer);
			}

			avi_url = account.avatar ?? "";
			avatar.clicked.connect (open_pfp_in_media_viewer);

			if (account.fields != null) {
				foreach (API.AccountField f in account.fields) {
					var row = new Adw.ActionRow ();
					var val = new Widgets.RichLabel (HtmlUtils.simplify (f.val));
					val.hexpand = true;
					val.xalign = 1;
					row.title = f.name;

					info.append (row);

					if (f.verified_at != null) {
						var verified_date = f.verified_at.slice (0, f.verified_at.last_index_of ("T"));
						var verified_label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
						var verified_checkmark = new Gtk.Image.from_icon_name ("tuba-check-round-outline-symbolic") {
							tooltip_text = _(@"Ownership of this link was checked on $verified_date")
						};

						verified_label_box.append (val);
						verified_label_box.append (verified_checkmark);

						row.add_suffix (verified_label_box);
						row.add_css_class ("ttl-verified-field");
					} else {
						row.add_suffix (val);
					};
				}
			}

			if (account.created_at != null) {
				var row = new Adw.ActionRow ();
				var parsed_date = new GLib.DateTime.from_iso8601 (account.created_at, null);
				parsed_date = parsed_date.to_timezone (new TimeZone.local ());

				var date_local = _("%B %e, %Y");
				var val = new Gtk.Label (parsed_date.format (date_local).replace (" ", "")) { // %e prefixes with whitespace on single digits
					wrap = true,
					xalign = 1,
					hexpand = true,
					tooltip_text = parsed_date.format ("%F")
				};

				// translators: as in created an account; this is used in Profiles in a row
				//				which has as value the date the profile was created on
				row.title = _("Joined");

				info.append (row);
				row.add_suffix (val);
				row.add_prefix (new Gtk.Image.from_icon_name ("tuba-contact-new-symbolic"));
			}
		}

		void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
			if (is_loaded)
				background.paintable = data;
		}
	}

	protected void build_profile_stats (Gtk.ListBox info) {
		var row = new Gtk.ListBoxRow ();
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
			homogeneous = true
		};

		// translators: the variable is the amount of posts a user has made
		var btn = build_profile_stats_button (_("%s Posts").printf (Tuba.Units.shorten (profile.statuses_count)));
		btn.clicked.connect (() => change_timeline_source ("statuses"));
		box.append (btn);

		// translators: the variable is the amount of people a user follows
		btn = build_profile_stats_button (_("%s Following").printf (Tuba.Units.shorten (profile.following_count)));
		btn.clicked.connect (() => change_timeline_source ("following"));
		box.append (btn);

		// translators: the variable is the amount of followers a user has
		btn = build_profile_stats_button (_("%s Followers").printf (Tuba.Units.shorten (profile.followers_count)));
		btn.clicked.connect (() => change_timeline_source ("followers"));
		box.append (btn);

		row.activatable = false;
		row.child = box;
		info.append (row);
	}

	protected Gtk.Button build_profile_stats_button (string btn_label) {
		var btn = new Gtk.Button.with_label (btn_label) {
			css_classes = { "flat", "ttl-profile-stat-button" }
		};

		var child_label = btn.child as Gtk.Label;
		child_label.wrap = true;
		child_label.justify = Gtk.Justification.CENTER;

		return btn;
	}

	protected void change_timeline_source (string t_source) {
		source = t_source;
		accepts = t_source == "statuses" ? typeof (API.Status) : typeof (API.Account);

		url = @"/api/v1/accounts/$(profile.id)/$t_source";
		invalidate_actions (true);
	}

	protected override void build_header () {
		base.build_header ();

		menu_button = new Gtk.MenuButton ();
		var menu_builder = new Gtk.Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		var menu = "profile-menu";
		menu_button.menu_model = menu_builder.get_object (menu) as MenuModel;
		menu_button.popover.width_request = 250;
		menu_button.icon_name = "tuba-view-more-symbolic";
		header.pack_end (menu_button);

		if (profile.is_self ()) {
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
		var dialog = new Dialogs.ProfileEdit (profile);
		dialog.saved.connect (on_edit_save);
		dialog.show ();
	}

	private void on_edit_save () {
		if (profile.is_self ()) {
			rs.invalidated.disconnect (on_rs_updated);
			column_view.remove (cover);
			cover = null;

			for (uint i = 0; i < model.get_n_items (); i++) {
				var status_obj = (API.Status)model.get_item (i);
				if (status_obj.formal.account.id == profile.id) {
					entity_cache.remove (status_obj.formal.uri);
				}
			}

			cover = build_cover ();
			cover.rsbtn.rs = this.rs;
			column_view.prepend (cover);
			cover.bind (accounts.active);
			build_profile_stats (cover.info);
			rs.invalidated.connect (on_rs_updated);

			on_refresh ();
		}
	}

	protected virtual Cover build_cover () {
		return new Cover ();
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

		//  source_action = new SimpleAction.stateful ("source", VariantType.STRING, source);
		//  source_action.change_state.connect (v => {
		//  	source = v.get_string ();
		//  	source_action.set_state (source);
		//  	accepts = (source == "statuses" ? typeof (API.Status) : typeof (API.Account));

		//  	url = @"/api/v1/accounts/$(profile.id)/$source";
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
			status.content = @"$(profile.handle) ";
			new Dialogs.Compose (status);
		});
		actions.add_action (mention_action);

		var copy_handle_action = new SimpleAction ("copy_handle", null);
		copy_handle_action.activate.connect (v => {
			Host.copy (profile.full_handle);
		});
		actions.add_action (copy_handle_action);

		muting_action = new SimpleAction.stateful ("muting", null, false);
		muting_action.change_state.connect (v => {
			var state = v.get_boolean ();
			rs.modify (state ? "mute" : "unmute");
		});
		actions.add_action (muting_action);

		hiding_reblogs_action = new SimpleAction.stateful ("hiding_reblogs", null, false);
		hiding_reblogs_action.change_state.connect (v => {
			if (!rs.following) {
				warning ("Trying to hide boosts while not following an account.");
				return;
			}

			var state = !v.get_boolean ();
			rs.modify ("follow", "reblogs", state.to_string ());
		});
		actions.add_action (hiding_reblogs_action);

		blocking_action = new SimpleAction.stateful ("blocking", null, false);
		blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block \"%s\"?") : _("Unblock \"%s\"?");

			var confirmed = app.question (
				q.printf (profile.handle),
				null,
				app.main_window,
				block ? _("Block") : _("Unblock"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect (res => {
				if (res == "yes") {
					rs.modify (block ? "block" : "unblock");
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
				q.printf (profile.domain),
				_("Blocking a domain will:\n\n• Remove its public posts and notifications from your timelines\n• Remove its followers from your account\n• Prevent you from following its users"), // vala-lint=line-length

				app.main_window,
				block ? _("Block") : _("Unblock"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect (res => {
				if (res == "yes") {
					var req = new Request.POST ("/api/v1/domain_blocks")
					.with_account (accounts.active)
					.with_param ("domain", profile.domain)
					.then (() => {
						rs.request ();
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
		muting_action.set_state (rs.muting);
		hiding_reblogs_action.set_state (!rs.showing_reblogs);
		hiding_reblogs_action.set_enabled (rs.following);
		blocking_action.set_state (rs.blocking);
		domain_blocking_action.set_state (rs.domain_blocking);
		domain_blocking_action.set_enabled (accounts.active.domain != profile.domain);
		ar_list_action.set_enabled (profile.id != accounts.active.id && rs.following);

		if (refresh) {
			page_next = null;
			on_refresh ();
		}
	}

	void on_rs_updated () {
		var label = "";
		if (cover.rsbtn.sensitive = rs != null) {
			if (rs.requested)
				label = _("Sent follow request");
			else if (rs.followed_by && rs.following)
				label = _("Mutuals");
			else if (rs.followed_by)
				label = _("Follows you");
		}

		cover.cover_badge_label = label;
		invalidate_actions (false);
	}

	public override Request append_params (Request req) {
		if (page_next == null && source == "statuses") {
			req.with_param ("exclude_replies", (!include_replies).to_string ());
			req.with_param ("only_media", only_media.to_string ());
			return base.append_params (req);
		}
		else return req;
	}

	public static void open_from_id (string id) {
		var msg = new Soup.Message ("GET", @"$(accounts.active.instance)/api/v1/accounts/$id");
		network.queue (msg, null, (sess, mess, in_stream) => {
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
		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
		var headerbar = new Adw.HeaderBar ();
		var toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		toast_overlay.child = spinner;

		box.append (headerbar);
		box.append (toast_overlay);
		var dialog = new Adw.Window () {
			// translators: the variable is an account handle
			title = _("Add or remove \"%s\" to or from a list").printf (profile.handle),
			modal = true,
			transient_for = app.main_window,
			content = box,
			default_width = 600,
			default_height = 550
		};
		spinner.start ();

		var preferences_page = new Adw.PreferencesPage ();
		var preferences_group = new Adw.PreferencesGroup () {
			// translators: the variable is an account handle
			title = _("Select the list to add or remove \"%s\" to or from:").printf (profile.handle)
		};

		var no_lists_page = new Adw.StatusPage () {
			icon_name = "tuba-error-symbolic",
			vexpand = true,
			title = _("You don't have any lists")
		};

		new Request.GET ("/api/v1/lists/")
			.with_account (accounts.active)
			.with_ctx (this)
			.on_error (on_error)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				if (Network.get_array_size (parser) > 0) {
					new Request.GET (@"/api/v1/accounts/$(profile.id)/lists")
					.with_account (accounts.active)
					.with_ctx (this)
					.on_error (on_error)
					.then ((sess2, msg2, in_stream2) => {
						var added = false;
						var in_list = new Gee.ArrayList<string> ();

						var parser2 = Network.get_parser_from_inputstream (in_stream2);
						Network.parse_array (msg2, parser2, node => {
							var list = API.List.from (node);
							in_list.add (list.id);
						});
						Network.parse_array (msg, parser, node => {
							var list = API.List.from (node);
							var is_already = in_list.contains (list.id);

							var add_button = new RowButton () {
								icon_name = is_already ? "tuba-minus-large-symbolic" : "tuba-plus-large-symbolic",
								tooltip_text = is_already
									? _("Remove \"%s\" from \"%s\"").printf (profile.handle, list.title)
									: _("Add \"%s\" to \"%s\"").printf (profile.handle, list.title),
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

			var endpoint = @"/api/v1/lists/$(list.id)/accounts/?account_ids[]=$(profile.id)";
			var req = button.remove ? new Request.DELETE (endpoint) : new Request.POST (endpoint);
			req
				.with_account (accounts.active)
				.with_ctx (this)
				.on_error (on_error)
				.then ((sess, msg) => {
					var toast_msg = "";
					if (button.remove) {
						//  translators: First variable is a handle, second variable is a list name
						toast_msg = _("User \"%s\" got removed from \"%s\"").printf (profile.handle, list.title);
						button.icon_name = "tuba-plus-large-symbolic";
						//  translators: First variable is a handle, second variable is a list name
						button.tooltip_text = _("Add \"%s\" to \"%s\"").printf (profile.handle, list.title);
					} else {
						//  translators: First variable is a handle, second variable is a list name
						toast_msg = _("User \"%s\" got added to \"%s\"").printf (profile.handle, list.title);
						button.icon_name = "tuba-minus-large-symbolic";
						//  translators: First variable is a handle, second variable is a list name
						button.tooltip_text = _("Remove \"%s\" from \"%s\"").printf (profile.handle, list.title);
					}

					button.remove = !button.remove;
					row.sensitive = true;

					var toast = new Adw.Toast (toast_msg);
					toast_overlay.add_toast (toast);
				})
				.exec ();
	}
}
