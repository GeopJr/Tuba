using Gtk;

public class Tootle.Views.Profile : Views.Timeline {

	public API.Account profile { get; construct set; }
	public API.Relationship rs { get; construct set; }
	public bool include_replies { get; set; default = false; }
	public bool only_media { get; set; default = false; }
	public string source { get; set; default = "statuses"; }

	SimpleAction media_action;
	SimpleAction replies_action;
	SimpleAction muting_action;
	SimpleAction hiding_reblogs_action;
	SimpleAction blocking_action;
	SimpleAction domain_blocking_action;

	ListBox profile_list;
	Label relationship;
	Widgets.TimelineMenu menu_button;

	Widgets.AdaptiveButton rs_button;
	SourceFunc? rs_button_action;

	weak ListBoxRow note_row;

	construct {
		build_actions ();

		var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/views/profile_header.ui");
		profile_list = builder.get_object ("profile_list") as ListBox;

		var hdr = builder.get_object ("grid") as Grid;
		column_view.pack_start (hdr, false, false, 0);
		column_view.reorder_child (hdr, 0);

		var avatar = builder.get_object ("avatar") as Widgets.Avatar;
		avatar.account = profile;

		var domain = "@" + profile.domain;
		menu_button.title.label = profile.handle.replace (domain, "");
		menu_button.subtitle.label = domain;
		if ("@" in profile.acct)
			menu_button.subtitle.show ();

		var handle = builder.get_object ("handle") as Widgets.RichLabel;
		profile.bind_property ("display-name", handle, "text", BindingFlags.SYNC_CREATE);

		note_row = builder.get_object ("note_row") as ListBoxRow;
		var note = builder.get_object ("note") as Widgets.MarkupView;
		profile.bind_property ("note", note, "content", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var text = (string) src;
			target.set_string (text);
			note_row.visible = text != "";
			return true;
		});

		relationship = builder.get_object ("relationship") as Label;
		rs.notify["id"].connect (on_rs_updated);

		rebuild_fields ();
	}

	public Profile (API.Account acc) {
		Object (
			profile: acc,
			rs: new API.Relationship.for_account (acc),
			label: acc.acct,
			url: @"/api/v1/accounts/$(acc.id)/statuses"
		);
	}
	~Profile () {
		menu_button.destroy ();
	}

	public override void build_header () {
		rs_button = new Widgets.AdaptiveButton ();
		rs_button.clicked.connect (() => {
			if (rs_button_action != null) {
				rs_button.sensitive = false;
				rs_button_action ();
			}
		});
		header.custom_title = menu_button = new Widgets.TimelineMenu ("profile-menu");

		if (profile.id != accounts.active.id)
			header.pack_end (rs_button);
	}

	void build_actions () {
		actions = new SimpleActionGroup ();

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

		var source_action = new SimpleAction.stateful ("source", VariantType.STRING, source);
		source_action.change_state.connect (v => {
			source = v.get_string ();
			source_action.set_state (source);
			accepts = source == "statuses" ? typeof (API.Status) : typeof (API.Account);

			url = @"/api/v1/accounts/$(profile.id)/$source";
			invalidate_actions (true);
		});
		actions.add_action (source_action);

		var mention_action = new SimpleAction ("mention", VariantType.STRING);
		mention_action.activate.connect (v => {
			var status = new API.Status.empty ();
			status.visibility = API.Visibility.from_string (v.get_string ());
			status.content = @"$(profile.handle) ";
			new Dialogs.Compose (status);
		});
		actions.add_action (mention_action);

		var copy_handle_action = new SimpleAction ("copy_handle", null);
		copy_handle_action.activate.connect (v => {
			Desktop.copy (profile.handle);
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
			var state = !v.get_boolean ();
			rs.modify ("follow", "reblogs", @"$state");
		});
		actions.add_action (hiding_reblogs_action);

		blocking_action = new SimpleAction.stateful ("blocking", null, false);
		blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block \"%s\"?") : _("Unblock \"%s\"?");
			var yes = app.question (q.printf (profile.handle));

			if (yes)
				rs.modify (block ? "block" : "unblock");
		});
		actions.add_action (blocking_action);

		domain_blocking_action = new SimpleAction.stateful ("domain_blocking", null, false);
		domain_blocking_action.change_state.connect (v => {
			var block = v.get_boolean ();
			var q = block ? _("Block Entire \"%s\"?") : _("Unblock Entire \"%s\"?");
			var yes = app.question (
				q.printf (profile.domain),
				_("Blocking a domain will:\n\n• Remove its public posts and notifications from your timelines\n• Remove its followers from your account\n• Prevent you from following its users")
			);

			if (yes) {
				var req = new Request.POST ("/api/v1/domain_blocks")
					.with_account (accounts.active)
					.with_param ("domain", profile.domain)
					.then (() => {
						rs.request ();
					});

				if (!block) req.method = "DELETE";
				req.exec ();
			}
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

	 void on_rs_updated () {
		var label = "";
		if (rs_button.sensitive = rs != null) {
			if (rs.requested)
				label = _("Sent follow request");
			else if (rs.followed_by && rs.following)
				label = _("Mutually follows you");
			else if (rs.followed_by)
				label = _("Follows you");


			string action_icon = "";
			string action_label = "";
			get_rs_button_state (ref action_label, ref action_icon, ref rs_button_action);
			rs_button.icon_name = action_icon;
			rs_button.label = action_label;

		}

		relationship.label = label;
		relationship.visible = label != "";

		invalidate_actions (false);
	}

	void get_rs_button_state (ref string label, ref string icon_name, ref SourceFunc? fn) {
		if (rs == null) return;

		if (rs.blocking) {
			label = _("Unblock");
			icon_name = "view-reveal-symbolic";
			fn = () => {
				blocking_action.change_state (false);
				rs_button.sensitive = true;
				return true;
			};
			return;
		}
		else if (rs.following || rs.requested) {
			label = _("Unfollow");
			icon_name = "list-remove-symbolic";
			fn = () => {
				rs.modify ("unfollow");
				return true;
			};
			return;
		}
		else if (!rs.following) {
			label = _("Follow");
			icon_name = "list-add-symbolic";
			fn = () => {
				rs.modify ("follow");
				return true;
			};
			return;
		}

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
		network.queue (msg, (sess, mess) => {
			var node = network.parse_node (mess);
			var acc = API.Account.from (node);
			window.open_view (new Views.Profile (acc));
		}, (status, reason) => {
			network.on_error (status, reason);
		});
	}

	[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/profile_field_row.ui")]
	protected class Field : ListBoxRow {

		[GtkChild]
		Widgets.RichLabel name_label;
		[GtkChild]
		Widgets.RichLabel value_label;

		public Field (API.AccountField field) {
			name_label.text = field.name;
			value_label.text = field.val;
		}

	}

	void rebuild_fields () {
		if (profile.fields != null) {
			foreach (Entity e in profile.fields) {
				var w = new Field (e as API.AccountField);
				profile_list.insert (w, -1);
			}
		}
	}

}
