using Gtk;

public class Tuba.Views.Profile : Views.Timeline {

	public API.Account profile { get; construct set; }
	public API.Relationship rs { get; construct set; }
	public bool include_replies { get; set; default = false; }
	public bool only_media { get; set; default = false; }
	public string source { get; set; default = "statuses"; }

	protected Cover cover;
	protected Label cover_badge;
	protected MenuButton menu_button;

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
		cover_badge = cover.cover_badge;
		cover.rsbtn.rs = this.rs;
		column_view.prepend (cover);
	}

	public Profile (API.Account acc) {
		Object (
			profile: acc,
			rs: new API.Relationship.for_account (acc),
			label: _("Profile"),
			is_profile: true,
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);
		append_pinned(acc.id);
		cover.bind (profile);
		build_profile_stats(cover.info);
		rs.invalidated.connect (on_rs_updated);
	}
	~Profile () {
		message("Destroying Profile view");
	}

	public void append_pinned(string acc_id) {
		new Request.GET (@"/api/v1/accounts/$(acc_id)/statuses")
			.with_account (account)
			.with_param ("pinned", "true")
			.with_ctx (this)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream(in_stream);

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

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/profile_header.ui")]
	protected class Cover : Box {

		[GtkChild] unowned Widgets.BackgroundWrapper background;
		[GtkChild] public unowned Label cover_badge;
		[GtkChild] public unowned ListBox info;
		[GtkChild] unowned Widgets.EmojiLabel display_name;
		[GtkChild] unowned Label handle;
		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Widgets.MarkupView note;
		[GtkChild] public unowned Widgets.RelationshipButton rsbtn;

		public void bind (API.Account account) {
			display_name.instance_emojis = account.emojis_map;
			display_name.content = account.display_name;
			handle.label = account.handle;
			avatar.account = account;
			note.instance_emojis = account.emojis_map;
			note.content = account.note;

			if (account.id != accounts.active.id) rsbtn.visible = true;

			if (account.header.contains("/headers/original/missing.png")) {
				avatar.bind_property("custom_image", background, "paintable", GLib.BindingFlags.SYNC_CREATE);
			} else {
				image_cache.request_paintable (account.header, on_cache_response);
				background.clicked.connect (() => app.main_window.show_media_viewer_single(account.header, background.paintable));
			}

			avatar.clicked.connect (() => app.main_window.show_media_viewer_single(account.avatar, avatar.custom_image));

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
						var verified_label_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
						var verified_checkmark = new Gtk.Image.from_icon_name("tuba-check-round-outline-symbolic") {
							tooltip_text = _(@"Ownership of this link was checked on $verified_date")
						};

						verified_label_box.append(val);
						verified_label_box.append(verified_checkmark);

						row.add_suffix(verified_label_box);
						row.add_css_class("ttl-verified-field");
					} else {
						row.add_suffix (val);
					};
				}
			}

			if (account.created_at != null) {
				var row = new Adw.ActionRow ();
				var parsed_date = new GLib.DateTime.from_iso8601 (account.created_at, null);

				var date_local = _("%B %e, %Y");
				var val = new Gtk.Label (parsed_date.format(date_local).replace(" ", "")) { // %e prefixes with whitespace on single digits
					wrap = true,
					xalign = 1,
					hexpand = true,
					tooltip_text = parsed_date.format(@"%F")
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
			background.paintable = data;
		}
	}

	protected void build_profile_stats(ListBox info) {
		var row = new Gtk.ListBoxRow ();
		var box = new Box (Orientation.HORIZONTAL, 0) {
			homogeneous = true
		};

		// translators: the variable is the amount of posts a user has made
		var btn = build_profile_stats_button(_("%lld Posts").printf (profile.statuses_count));
		btn.clicked.connect(() => change_timeline_source("statuses"));
		box.append(btn);

		// translators: the variable is the amount of people a user follows
		btn = build_profile_stats_button(_("%lld Following").printf (profile.following_count));
		btn.clicked.connect(() => change_timeline_source("following"));
		box.append(btn);

		// translators: the variable is the amount of followers a user has
		btn = build_profile_stats_button(_("%lld Followers").printf (profile.followers_count));
		btn.clicked.connect(() => change_timeline_source("followers"));
		box.append(btn);

		row.activatable = false;
		row.child = box;
		info.append (row);
	}

	protected Button build_profile_stats_button(string btn_label) {
		var btn = new Button.with_label(btn_label);
		btn.add_css_class("flat");
		btn.add_css_class("ttl-profile-stat-button");

		var child_label = btn.child as Label;
		child_label.wrap = true;
		child_label.justify = Justification.CENTER;

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

		menu_button = new MenuButton ();
		var menu_builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		var menu = "profile-menu";
		menu_button.menu_model = menu_builder.get_object (menu) as MenuModel;
		menu_button.popover.width_request = 250;
		menu_button.icon_name = "tuba-view-more-symbolic";
		header.pack_end (menu_button);

		//  rs_button = new Widgets.RelationshipButton () {
		//  	rs = this.rs
		//  };
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
			create_ar_list_dialog().show();
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
			rs.modify ("follow", "reblogs", @"$state");
		});
		actions.add_action (hiding_reblogs_action);

		blocking_action = new SimpleAction.stateful ("blocking", null, false);
		blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block \"%s\"?") : _("Unblock \"%s\"?");
			warning (q);

			var confirmed = app.question (
				q.printf (profile.handle),
				null,
				app.main_window,
				block ? _("Block") : _("Unblock"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect(res => {
				if (res == "yes") {
					rs.modify (block ? "block" : "unblock");
				}
				confirmed.destroy();
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
				_("Blocking a domain will:\n\n• Remove its public posts and notifications from your timelines\n• Remove its followers from your account\n• Prevent you from following its users"),
				app.main_window,
				block ? _("Block") : _("Unblock"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect(res => {
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
				confirmed.destroy();
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
		ar_list_action.set_enabled(profile.id != accounts.active.id && rs.following);

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

		cover_badge.label = label;
		cover_badge.visible = label != "";

		invalidate_actions (false);
	}

	public override Request append_params (Request req) {
		if (page_next == null && source == "statuses") {
			req.with_param ("exclude_replies", @"$(!include_replies)");
			req.with_param ("only_media", @"$(only_media)");
			return base.append_params (req);
		}
		else return req;
	}

	public static void open_from_id (string id) {
		var msg = new Soup.Message ("GET", @"$(accounts.active.instance)/api/v1/accounts/$id");
		network.queue (msg, null, (sess, mess, in_stream) => {
			var parser = Network.get_parser_from_inputstream(in_stream);
			var node = network.parse_node (parser);
			var acc = API.Account.from (node);
			app.main_window.open_view (new Views.Profile (acc));
		},
		network.on_error);
	}

	public class RowButton : Button {
		public bool remove { get; set; default = false; }
	}

	public Adw.Window create_ar_list_dialog() {
		var spinner = new Spinner() {
			spinning = true,
			halign = Align.CENTER,
			valign = Align.CENTER,
			vexpand = true,
			hexpand = true,
			width_request = 32,
			height_request = 32
		};
		var box = new Box(Orientation.VERTICAL, 6);
		var headerbar = new Adw.HeaderBar();
		var toast_overlay = new Adw.ToastOverlay() {
			vexpand = true,
			valign = Align.CENTER
		};
		toast_overlay.child = spinner;

		box.append(headerbar);
		box.append(toast_overlay);
		var dialog = new Adw.Window() {
			// translators: the variable is an account handle
			title = _("Add or remove \"%s\" to or from a list").printf (profile.handle),
			modal = true,
			transient_for = app.main_window,
			content = box,
			default_width = 600,
			default_height = 550
		};
		spinner.start();

		var preferences_page = new Adw.PreferencesPage();
		var preferences_group = new Adw.PreferencesGroup() {
			// translators: the variable is an account handle
			title = _("Select the list to add or remove \"%s\" to or from:").printf (profile.handle)
		};

		var no_lists_page = new Adw.StatusPage() {
			icon_name = "tuba-error-symbolic",
			vexpand = true,
			title = _("You don't have any lists")
		};

		new Request.GET (@"/api/v1/lists/")
			.with_account (accounts.active)
			.with_ctx (this)
			.on_error (on_error)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream(in_stream);
				if (Network.get_array_size(parser) > 0) {
					new Request.GET (@"/api/v1/accounts/$(profile.id)/lists")
					.with_account (accounts.active)
					.with_ctx (this)
					.on_error (on_error)
					.then ((sess2, msg2, in_stream2) => {
						var added = false;
						var in_list = new Gee.ArrayList<string>();

						var parser2 = Network.get_parser_from_inputstream(in_stream2);
						Network.parse_array (msg2, parser2, node => {
							var list = API.List.from (node);
							in_list.add(list.id);
						});
						Network.parse_array (msg, parser, node => {
							var list = API.List.from (node);
							var is_already = in_list.contains(list.id);

							var add_button = new RowButton() {
								icon_name = is_already ? "tuba-minus-large-symbolic" : "tuba-plus-large-symbolic",
								tooltip_text = is_already ? _("Remove \"%s\" from \"%s\"").printf (profile.handle, list.title) : _("Add \"%s\" to \"%s\"").printf (profile.handle, list.title),
								halign = Align.CENTER,
								valign = Align.CENTER
							};
							add_button.add_css_class("flat");
							add_button.add_css_class("circular");
							add_button.remove = is_already;

							var row = new Adw.ActionRow() {
								title = list.title
							};
							row.add_suffix(add_button);

							add_button.clicked.connect(() => {
								handle_list_edit(list, row, toast_overlay, add_button);
							});

							preferences_group.add(row);
							added = true;
						});

						if (added) {
							preferences_page.add(preferences_group);

							toast_overlay.child = preferences_page;
							toast_overlay.valign = Align.FILL;
						} else {
							toast_overlay.child = no_lists_page;
						}
					})
					.exec();
				} else {
					toast_overlay.child = no_lists_page;
				}	
			})
			.exec ();

		return dialog;
	}

	public void handle_list_edit(API.List list, Adw.ActionRow row, Adw.ToastOverlay toast_overlay, RowButton button) {
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

					var toast = new Adw.Toast(toast_msg);
					toast_overlay.add_toast(toast);
				})
				.exec();
	}
}
