using Gtk;

public class Tooth.Views.Profile : Views.Timeline {

	public API.Account profile { get; construct set; }
	public API.Relationship rs { get; construct set; }
	public bool include_replies { get; set; default = false; }
	public bool only_media { get; set; default = false; }
	public string source { get; set; default = "statuses"; }

	protected Cover cover;
	protected MenuButton menu_button;
	protected Widgets.RelationshipButton rs_button;

	protected SimpleAction media_action;
	protected SimpleAction replies_action;
	protected SimpleAction muting_action;
	protected SimpleAction hiding_reblogs_action;
	protected SimpleAction blocking_action;
	protected SimpleAction domain_blocking_action;
	protected SimpleAction source_action;

	construct {
		cover = build_cover ();
		column_view.prepend (cover);
	}

	public Profile (API.Account acc) {
		Object (
			profile: acc,
			rs: new API.Relationship.for_account (acc),
			label: _("Profile"),
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);
		cover.bind (profile);
	}

	[GtkTemplate (ui = "/dev/geopjr/tooth/ui/views/profile_header.ui")]
	protected class Cover : Box {

		[GtkChild] unowned Widgets.Background background;
		[GtkChild] unowned ListBox info;
		[GtkChild] unowned Widgets.RichLabelContainer display_name;
		[GtkChild] unowned Label handle;
		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Widgets.MarkupView note;

		public void bind (API.Account account) {
			//  display_name.label = account.display_name;
			display_name.set_label(account.display_name, null, account.emojis_map);
			handle.label = account.handle;
			avatar.account = account;
			note.content = account.note;

			image_cache.request_paintable (account.header, on_cache_response);

			if (account.fields != null) {
				foreach (API.AccountField f in account.fields) {
					var row = new Adw.ActionRow ();
					var val = new Widgets.RichLabel (HtmlUtils.simplify (f.val));
					val.wrap = false;
					val.xalign = 1;
					row.title = f.name;
					row.add_suffix (val);

					info.append (row);
				}
			}

		}

		void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
			background.paintable = data;
		}

	}

	protected override void build_header () {
		base.build_header ();

		menu_button = new MenuButton ();
		var menu_builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/menus.ui");
		var menu = "profile-menu";
		menu_button.menu_model = menu_builder.get_object (menu) as MenuModel;
		menu_button.popover.width_request = 250;
		menu_button.icon_name = "tooth-view-more-symbolic";
		header.pack_end (menu_button);

		rs_button = new Widgets.RelationshipButton () {
			rs = this.rs
		};
		if (profile.id != accounts.active.id)
			header.pack_end (rs_button);
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

		source_action = new SimpleAction.stateful ("source", VariantType.STRING, source);
		source_action.change_state.connect (v => {
			source = v.get_string ();
			source_action.set_state (source);
			accepts = (source == "statuses" ? typeof (API.Status) : typeof (API.Account));

			url = @"/api/v1/accounts/$(profile.id)/$source";
			invalidate_actions (true);
		});
		actions.add_action (source_action);

		var mention_action = new SimpleAction ("mention", VariantType.STRING);
		mention_action.activate.connect (v => {
			var status = new API.Status.empty ();
			status.visibility = v.get_string ();
			status.content = @"$(profile.handle) ";
			new Dialogs.Compose (status);
		});
		actions.add_action (mention_action);

		//FIXME: Take a variant to copy "handle" and "uri"
		var copy_handle_action = new SimpleAction ("copy_handle", null);
		copy_handle_action.activate.connect (v => {
			Host.copy (profile.handle);
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

		if (refresh) {
			page_next = null;
			on_refresh ();
		}
	}

	// TODO: RS badges
	//  void on_rs_updated () {
		// var label = "";
		// if (rs_button.sensitive = rs != null) {
		// 	if (rs.requested)
		// 		label = _("Sent follow request");
		// 	else if (rs.followed_by && rs.following)
		// 		label = _("Mutually follows you");
		// 	else if (rs.followed_by)
		// 		label = _("Follows you");


		// 	string action_icon = "";
		// 	string action_label = "";
		// 	get_rs_button_state (ref action_label, ref action_icon, ref rs_button_action);
		// 	rs_button.icon_name = action_icon;
		// 	rs_button.label = action_label;

		// }

		// relationship.label = label;
		// relationship.visible = label != "";

	//  	invalidate_actions (false);
	//  }

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
		network.queue (msg, (sess, mess) => {
			var node = network.parse_node (mess);
			var acc = API.Account.from (node);
			app.main_window.open_view (new Views.Profile (acc));
		},
		network.on_error);
	}

}
