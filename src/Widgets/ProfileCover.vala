[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/profile_header.ui")]
protected class Tuba.Widgets.Cover : Gtk.Box {
	static construct {
		typeof (Widgets.Background).ensure ();
		typeof (Widgets.Avatar).ensure ();
		typeof (Widgets.RelationshipButton).ensure ();
		typeof (Widgets.EmojiLabel).ensure ();
		typeof (Widgets.MarkupView).ensure ();
	}

	public class MutualsButtonContent : Gtk.Box {
		Gtk.Box avi_box;
		Widgets.EmojiLabel emoji_label;
		construct {
			this.orientation = Gtk.Orientation.HORIZONTAL;
			this.spacing = 6;

			avi_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
			emoji_label = new Widgets.EmojiLabel () {
				use_markup = false,
				ellipsize = true,
				valign = Gtk.Align.CENTER
			};
			emoji_label.add_css_class ("dim-label");

			this.append (avi_box);
			this.append (emoji_label);
		}

		public MutualsButtonContent (Gee.ArrayList<API.Account> mutual_accounts) {
			Gee.HashMap<string, string> total_custom_emojis = new Gee.HashMap<string, string> ();
			string[] display_named = {};

			int max_accs = 3;
			if (mutual_accounts.size == max_accs + 1) max_accs = max_accs + 1;

			for (int i = 0; i < int.min (max_accs, mutual_accounts.size); i++) {
				var acc = mutual_accounts.get (i);
				string display_name = acc.display_name;

				if (display_name.index_of_char (':') >= 0) {
					acc.emojis_map.foreach (e => {
						string new_moji_name = @"$(e.key)_$i";
						display_name = display_name.replace (@":$(e.key):", @":$new_moji_name:");
						total_custom_emojis.set (new_moji_name, e.value);

						return true;
					});
				}

				var avi = new Widgets.Avatar () {
					account = acc,
					size = 6
				};
				if (i == 0) avi.add_css_class ("first-avi");
				avi.add_css_class ("no-min-size");
				avi.add_css_class ("mutual-avi");
				avi_box.append (avi);

				display_named += display_name;
			}

			emoji_label.instance_emojis = total_custom_emojis;

			int others_count = mutual_accounts.size - max_accs;
			if (others_count > 0) {
				this.tooltip_text = emoji_label.content = GLib.ngettext (
					// translators: button on profiles that when clicked shows a list of familiar followers.
					//				The first variable is a comma-separated list of people (e.g. GeopJr, Tuba, GNOME).
					//				If your language requires pronouns you may add a : after 'by' so it's clear it's a
					//				list of names. The second variable is the amount of other familiar followers, not
					//				displayed in the list. The singular version will not be used.
					"Followed by %s & %s Other", "Followed by %s & %s Others",
					(ulong) others_count
				).printf (string.joinv (", ", display_named), Utils.Units.shorten (others_count));
			} else {
				string display_name_list;
				switch (display_named.length) {
					case 1:
						display_name_list = display_named[0];
						break;
					default:
						int last_index = display_named.length - 1;
						display_name_list = @"$(string.joinv(", ", display_named[0:last_index])) & $(display_named[last_index])";
						break;
				}

				// translators: button on profiles that when clicked shows a list of familiar followers.
				//				The variable is a comma-separated list of people (e.g. GeopJr, Tuba, GNOME).
				//				If your language requires pronouns you may add a : after 'by' so it's clear it's a
				//				list of names. This is the version of the string that has 0 'others'.
				this.tooltip_text = emoji_label.content = _("Followed by %s").printf (display_name_list);
			}
		}
	}

	[GtkChild] unowned Adw.WrapBox roles;
	[GtkChild] unowned Widgets.Background background;
	[GtkChild] unowned Gtk.Label cover_badge;
	[GtkChild] unowned Gtk.Image cover_bot_badge;
	[GtkChild] unowned Gtk.Box cover_badge_box;
	[GtkChild] unowned Gtk.ListBox info;
	[GtkChild] unowned Widgets.EmojiLabel display_name;
	[GtkChild] unowned Gtk.Label handle;
	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Gtk.Button moved_btn;
	[GtkChild] public unowned Widgets.MarkupView note;
	[GtkChild] public unowned Widgets.RelationshipButton rsbtn;
	[GtkChild] unowned Gtk.MenuButton mutuals_button;

	[GtkChild] unowned Adw.EntryRow note_entry_row;
	[GtkChild] unowned Gtk.ListBoxRow note_row;
	[GtkChild] unowned Gtk.Label note_error;

	[GtkChild] unowned Gtk.Image supporter_icon;

	public API.Relationship rs { get; construct set; }
	public signal void rs_invalidated ();
	public signal void timeline_change (string timeline);
	public signal void aria_updated (string new_aria);

	~Cover () {
		debug ("Destroying Profile Cover");
	}

	void toggle_scale_emoji_hover () {
		Tuba.toggle_css (this, settings.scale_emoji_hover, "lww-scale-emoji-hover");
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

	public string note_error_label {
		get {
			return note_error.label;
		}

		set {
			note_entry_row.show_apply_button = note_entry_row.text != rsbtn.rs.note && value == "";
			if (note_error.label == value) return;

			note_error.visible = value != "";
			note_error.label = value;

			if (value != "") {
				note_entry_row.add_css_class ("error");
			} else {
				note_entry_row.remove_css_class ("error");
			}
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

	public void update_aria () {
		// translators: This is an accessibility label.
		//				Screen reader users are going to hear this a lot,
		//				please be mindful.
		//				The first variable is the author's name and the
		//				second one is the author's handle.
		string aria_profile = _("%s (%s)'s profile.").printf (
			display_name.content,
			handle.label
		);

		string aria_relationship = "";
		if (cover_badge.visible && cover_badge_label != "") {
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is a string representation of the
			//				relationship (e.g. Mutuals, Follows You...)
			aria_relationship = _("Relationship: %s.").printf (cover_badge_label);
		}

		string aria_fileds = "";
		if (total_fields > 0) {
			aria_fileds = GLib.ngettext (
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				//				The variable is the amount of fields the profile
				//				has.
				"Contains %d field.", "Contains %d fields.",
				(ulong) total_fields
			).printf (total_fields);

			this.fields_box_row.update_property (
				Gtk.AccessibleProperty.LABEL,
				aria_fileds,
				-1
			);
		}

		string final_aria = "%s %s".printf (
			aria_profile,
			aria_relationship
		);

		if (_mini) {
			final_aria += @" $stats_string";
		}

		this.info.update_property (
			Gtk.AccessibleProperty.LABEL,
			final_aria,
			-1
		);

		final_aria += @" $aria_fileds";

		aria_updated (final_aria);
	}

	private string avi_url { get; set; default=""; }
	private string header_url { get; set; default=""; }
	void open_header_in_media_viewer () {
		app.main_window.show_media_viewer (header_url, Tuba.Attachment.MediaType.IMAGE, background.paintable, background, true);
	}

	void open_pfp_in_media_viewer () {
		app.main_window.show_media_viewer (avi_url, Tuba.Attachment.MediaType.IMAGE, avatar.custom_image, avatar, true);
	}

	public signal void avatar_clicked ();
	private void on_avatar_clicked () {
		avatar_clicked ();
	}

	API.Account? moved_to_account = null;
	bool _mini = false;
	Gtk.FlowBox fields_box;
	Gtk.ListBoxRow fields_box_row;
	int total_fields = 0;
	string stats_string = "";
	string profile_id;
	public Cover (Views.Profile.ProfileAccount profile, bool mini = false) {
		profile_id = profile.account.id;
		if (settings.scale_emoji_hover)
			this.add_css_class ("lww-scale-emoji-hover");
		settings.notify["scale-emoji-hover"].connect (toggle_scale_emoji_hover);
		bool is_self = profile.account.id == accounts.active.id;

		_mini = mini;
		if (mini) {
			note_row.sensitive = false;
		} else if (!is_self) {
			moved_btn.clicked.connect (on_moved_btn_clicked);
			if (accounts.active.tuba_api_versions.mastodon > 0) {
				GLib.Idle.add (populate_mutuals);
			}
		}

		if (GLib.str_hash (profile.account.full_handle.down ()).to_string () in settings.contributors) {
			supporter_icon.visible = true;
			this.add_css_class ("thanks");
		}

		if (!is_self) {
			note_entry_row.notify["text"].connect (on_note_changed);
			profile.rs.invalidated.connect (on_rs_invalidation);
			rsbtn.handle = profile.account.handle;
			rsbtn.rs = profile.rs;
			rsbtn.visible = true;
		}

		if (mini) {
			avatar.clicked.connect (on_avatar_clicked);
		} else {
			avatar.clicked.connect (open_pfp_in_media_viewer);
		}

		fields_box = new Gtk.FlowBox () {
			max_children_per_line = app.is_mobile ? 1 : 2,
			min_children_per_line = 1,
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = {"ttl-profile-fields-box"}
		};
		fields_box_row = new Gtk.ListBoxRow () {
			child = fields_box,
			activatable = false,
			css_classes = {"ttl-profile-fields-box-container"}
		};
		info.append (fields_box_row);

		if (!mini) {
			build_profile_stats (profile.account);
		} else {
			background.height_request = 64;

			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of posts a user has made.
			string posts_str = GLib.ngettext (
				"%s Post",
				"%s Posts",
				(ulong) profile.account.statuses_count
			).printf (@"<b>$(Utils.Units.shorten (profile.account.statuses_count))</b>");

			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of followers a user has.
			string followers_str = GLib.ngettext (
				"%s Follower",
				"%s Followers",
				(ulong) profile.account.statuses_count
			).printf (@"<b>$(Utils.Units.shorten (profile.account.followers_count))</b>");

			stats_string = "<span allow_breaks=\"false\">%s</span>   <span allow_breaks=\"false\">%s</span>   <span allow_breaks=\"false\">%s</span>".printf (
				posts_str,
				// translators: Used in profile stats.
				//              The variable is a shortened number of the amount of people a user follows.
				_("%s Following").printf (@"<b>$(Utils.Units.shorten (profile.account.following_count))</b>"),
				followers_str
			);

			info.append (
				new Gtk.ListBoxRow () {
					activatable = false,
					child = new Gtk.Label (stats_string) {
						wrap = true,
						wrap_mode = Pango.WrapMode.WORD_CHAR,
						hexpand = true,
						xalign = 0.0f,
						use_markup = true,
						css_classes = {"account-stats"},
						valign = Gtk.Align.CENTER,
						margin_start = 12,
						margin_end = 12,
						margin_top = 6,
						margin_bottom = 6,
					}
				}
			);
		}
		update_cover_from_profile (profile.account);

		if (header_url != "" && !mini)
			background.clicked.connect (open_header_in_media_viewer);

		app.notify["is-mobile"].connect (update_fields_max_columns);
	}

	Gee.ArrayList<API.Account>? mutual_accounts = null;
	Gtk.ListBox? mutuals_listbox = null;
	private bool populate_mutuals () {
		mutuals_button.visible = false;

		new Request.GET ("/api/v1/accounts/familiar_followers")
			.with_account (accounts.active)
			.with_param ("id", profile_id)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				if (node == null) return;

				Value res_accounts;
				Entity.des_list (out res_accounts, node, typeof (API.FamiliarFollowers));
				var res_mutual_accounts = (Gee.ArrayList<API.FamiliarFollowers>) res_accounts;
				if (res_mutual_accounts.size == 0) return;

				mutual_accounts = res_mutual_accounts.get (0).accounts;
				if (mutual_accounts.size > 0) {
					mutuals_button.visible = true;

					mutuals_button.child = new MutualsButtonContent (mutual_accounts);
					mutuals_listbox = new Gtk.ListBox () {
						selection_mode = Gtk.SelectionMode.NONE,
						css_classes = {"boxed-list"}
					};

					mutuals_button.popover = new Gtk.Popover () {
						child = new Gtk.ScrolledWindow () {
							child = mutuals_listbox,
							hexpand = true,
							vexpand = true,
							hscrollbar_policy = Gtk.PolicyType.NEVER,
							max_content_height = 500,
							width_request = 360,
							propagate_natural_height = true
						}
					};

					mutuals_button.notify["active"].connect (on_mutuals_popover);
				}
			})
			.exec ();

		return GLib.Source.REMOVE;
	}

	private void on_mutuals_popover () {
		if (mutual_accounts == null || mutuals_listbox == null) return;

		foreach (var acc in mutual_accounts) {
			mutuals_listbox.append (new Widgets.EmojiReactionAccounts.AccountRow (acc));
		}

		mutual_accounts = null;
		mutuals_listbox = null;
		mutuals_button.notify["active"].disconnect (on_mutuals_popover);
	}

	public void update_cover_from_profile (API.Account profile) {
		handle.label = profile.handle;

		if (display_name.content != profile.display_name) {
			display_name.instance_emojis = profile.emojis_map;
			display_name.content = profile.display_name;
		}

		avi_url = profile.avatar ?? "";
		avatar.account = profile;
		avatar.alternative_text = profile.avatar_description;

		if (note.content != profile.note) {
			note.instance_emojis = profile.emojis_map;
			note.content = profile.note;
		}

		cover_bot_badge.visible = profile.bot;
		update_cover_badge ();

		var w = roles.get_first_child ();
		while (w != null) {
			roles.remove (w);
			w = w.get_next_sibling ();
		};

		if (profile.roles != null && profile.roles.size > 0) {
			roles.visible = true;

			foreach (API.AccountRole role in profile.roles) {
				var role_widget = role.to_widget ();
				role_widget.add_css_class ("profile-role-border-radius");

				roles.append (role_widget);
			}
		} else {
			roles.visible = false;
		}

		if (profile.header.contains ("/headers/original/missing.png")) {
			header_url = "";
			background.paintable = avatar.custom_image;
		} else {
			header_url = profile.header ?? "";
			Tuba.Helper.Image.request_paintable (profile.header, null, false, on_cache_response);
		}
		background.alternative_text = profile.header_description;

		if (!_mini && profile.moved != null) {
			moved_btn.visible = true;
			moved_btn.child = new Gtk.Label (
				// translators: Button label shown when a user has moved to another instance.
				//				The first variable is this account's handle while the second
				//				is the moved-to account's handle
				_("%s has moved to %s").printf (@"<b>$(profile.full_handle)</b>", @"<b>$(profile.moved.full_handle)</b>")
			) {
				use_markup = true,
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR
			};
			moved_to_account = profile.moved;
		} else {
			moved_btn.visible = false;
		}

		fields_box.remove_all ();
		total_fields = 0;
		if (profile.fields != null || profile.created_at != null) {
			var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
			total_fields = profile.fields.size;

			foreach (API.AccountField f in profile.fields) {
				var row = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
					css_classes = {"ttl-profile-field"}
				};
				var val = new Widgets.RichLabel (Utils.Htmlx.simplify (f.val)) {
					use_markup = true,
					xalign = 0,
					selectable = true
				};

				var title_label = new Widgets.EmojiLabel () {
					use_markup = false,
					css_classes = {"dim-label"}
				};
				title_label.instance_emojis = profile.emojis_map;
				title_label.content = f.name;

				fields_box.append (row);
				sizegroup.add_widget (row);
				if (f.verified_at != null) {
					var verified_date = f.verified_at.slice (0, f.verified_at.last_index_of ("T"));
					var verified_label_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
					var verified_checkmark = new Gtk.Image.from_icon_name ("tuba-verified-checkmark-symbolic") {
						tooltip_text = _(@"Ownership of this link was checked on $verified_date")
					};

					verified_label_box.append (title_label);
					verified_label_box.append (verified_checkmark);

					row.append (verified_label_box);
					row.add_css_class ("ttl-verified-field");
				} else {
					row.append (title_label);
				};

				row.append (val);
			}

			if (profile.created_at != null) {
				total_fields += 1;
				var row = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
					css_classes = {"ttl-profile-field"}
				};
				var parsed_date = new GLib.DateTime.from_iso8601 (profile.created_at, null);
				parsed_date = parsed_date.to_timezone (new TimeZone.local ());

				var date_local = _("%B %e, %Y");
				var val = new Gtk.Label (parsed_date.format (date_local).replace (" ", "")) { // %e prefixes with whitespace on single digits
					wrap = true,
					xalign = 0,
					hexpand = true,
					tooltip_text = parsed_date.format ("%F")
				};

				var creation_date_time = new GLib.DateTime.from_iso8601 (profile.created_at, null);
				var today_date_time = new GLib.DateTime.now_local ();
				bool is_birthday =
					creation_date_time.get_month () == today_date_time.get_month () && creation_date_time.get_day_of_month () == today_date_time.get_day_of_month ();

				var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
				// translators: as in created an account; this is used in Profiles in a row
				//				which has as value the date the profile was created on
				title_box.append (new Gtk.Label (_("Joined")) {
					css_classes = {"dim-label"}
				});

				if (is_birthday) {
					if (total_fields == 1) {
						fields_box.add_css_class ("ttl-birthday-field");
					} else {
						row.add_css_class ("ttl-birthday-field");
					}

					title_box.prepend (new Gtk.Image.from_icon_name ("tuba-birthday-symbolic"));
				} else {
					title_box.prepend (new Gtk.Image.from_icon_name ("contact-new-symbolic"));
				}

				row.append (title_box);
				row.append (val);

				fields_box.append (row);
				sizegroup.add_widget (row);
			}

			fields_box_row.remove_css_class ("odd");
			fields_box_row.remove_css_class ("signle");

			if (total_fields % 2 != 0) {
				fields_box_row.add_css_class ("odd");
			}

			if (total_fields == 1) {
				fields_box_row.add_css_class ("single");
			}
		}

		if (posts_btn != null && following_btn != null && followers_btn != null) {
			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of posts a user has made.
			posts_btn.label_template = GLib.ngettext (
				"%s Post",
				"%s Posts",
				(ulong) profile.statuses_count
			);
			posts_btn.amount = profile.statuses_count;

			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of people a user follows.
			following_btn.label_template = _("%s Following");
			following_btn.amount = profile.following_count;

			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of followers a user has.
			followers_btn.label_template = GLib.ngettext (
				"%s Follower",
				"%s Followers",
				(ulong) profile.followers_count
			);
			followers_btn.amount = profile.followers_count;
		}

		update_aria ();
	}

	private void on_rs_invalidation (API.Relationship rs) {
		cover_badge_label = rs.to_string ();
		note_row.visible = _mini ? rs.note != "" : rs.note != null;
		if (note_row.visible) note_entry_row.text = rs.note;

		if (!_mini) app.relationship_invalidated (rs);

		rs_invalidated ();
		update_aria ();
	}

	private void update_fields_max_columns () {
		fields_box.max_children_per_line = app.is_mobile ? 1 : 2;
	}

	private void on_moved_btn_clicked () {
		if (moved_to_account != null) moved_to_account.open ();
	}

	protected class ProfileStatsButton : Gtk.Button {
		public string label_template { get; set; default = "%s"; }
		public int64 amount {
			set {
				this.label = label_template.printf (Utils.Units.shorten (value));
				this.tooltip_text = label_template.printf (value.to_string ());
			}
		}

		construct {
			this.css_classes = { "flat", "ttl-profile-stat-button" };
			this.hexpand = true;
			this.label = "";

			var child_label = this.child as Gtk.Label;
			child_label.wrap = true;
			child_label.justify = Gtk.Justification.CENTER;
		}
	}

	ProfileStatsButton? posts_btn;
	ProfileStatsButton? followers_btn;
	ProfileStatsButton? following_btn;
	protected void build_profile_stats (API.Account account) {
		var row = new Gtk.ListBoxRow ();
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

		posts_btn = new ProfileStatsButton ();
		posts_btn.clicked.connect (() => timeline_change ("statuses"));
		sizegroup.add_widget (posts_btn);
		box.append (posts_btn);

		var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		following_btn = new ProfileStatsButton ();
		following_btn.clicked.connect (() => timeline_change ("following"));
		sizegroup.add_widget (following_btn);
		box.append (following_btn);

		separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		followers_btn = new ProfileStatsButton ();
		followers_btn.clicked.connect (() => timeline_change ("followers"));
		sizegroup.add_widget (followers_btn);
		box.append (followers_btn);

		row.activatable = false;
		row.focusable = false;
		row.child = box;
		info.append (row);
	}

	void on_cache_response (Gdk.Paintable? data) {
		background.paintable = data;
	}

	[GtkCallback]
	void on_note_apply () {
		if (!note_row.visible) return;
		if (note_error_label != "") return;
		rsbtn.rs.modify_note (note_entry_row.text);
	}

	void on_note_changed () {
		if (note_entry_row.text.length >= 2000) {
			note_error_label = _("Error: Note is over 2000 characters long");
			return;
		}

		note_error_label = "";
	}
}
