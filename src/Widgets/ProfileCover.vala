[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/profile_header.ui")]
protected class Tuba.Widgets.Cover : Gtk.Box {
	static construct {
		typeof (Widgets.Background).ensure ();
		typeof (Widgets.Avatar).ensure ();
		typeof (Widgets.RelationshipButton).ensure ();
		typeof (Widgets.EmojiLabel).ensure ();
		typeof (Widgets.MarkupView).ensure ();
	}

	[GtkChild] unowned Gtk.FlowBox roles;
	[GtkChild] unowned Widgets.Background background;
	[GtkChild] unowned Gtk.Label cover_badge;
	[GtkChild] unowned Gtk.Image cover_bot_badge;
	[GtkChild] unowned Gtk.Box cover_badge_box;
	[GtkChild] public unowned Gtk.ListBox info;
	[GtkChild] unowned Widgets.EmojiLabel display_name;
	[GtkChild] unowned Gtk.Label handle;
	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] public unowned Widgets.MarkupView note;
	[GtkChild] public unowned Widgets.RelationshipButton rsbtn;

	[GtkChild] unowned Adw.EntryRow note_entry_row;
	[GtkChild] unowned Gtk.ListBoxRow note_row;
	[GtkChild] unowned Gtk.Label note_error;

	[GtkChild] unowned Gtk.Image supporter_icon;

	public API.Relationship rs { get; construct set; }
	public signal void rs_invalidated ();
	public signal void timeline_change (string timeline);
	public signal void filter_change (Views.Profile.Filter filter);
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

			if (fields_box_row != null) {
				this.fields_box_row.update_property (
					Gtk.AccessibleProperty.LABEL,
					aria_fileds,
					-1
				);
			}
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

	bool _mini = false;
	Gtk.FlowBox fields_box;
	Gtk.ListBoxRow fields_box_row;
	int total_fields = 0;
	string stats_string = "";
	public Cover (Views.Profile.ProfileAccount profile, bool mini = false) {
		if (settings.scale_emoji_hover)
			this.add_css_class ("lww-scale-emoji-hover");
		settings.notify["scale-emoji-hover"].connect (toggle_scale_emoji_hover);

		_mini = mini;
		if (mini) note_row.sensitive = false;

		if (GLib.str_hash (profile.account.full_handle.down ()).to_string () in settings.contributors) {
			supporter_icon.visible = true;
			this.add_css_class ("thanks");
		}

		display_name.instance_emojis = profile.account.emojis_map;
		display_name.content = profile.account.display_name;
		handle.label = profile.account.handle;
		avatar.account = profile.account;
		note.instance_emojis = profile.account.emojis_map;
		note.content = profile.account.note;
		cover_bot_badge.visible = profile.account.bot;
		update_cover_badge ();

		if (profile.account.roles != null && profile.account.roles.size > 0) {
			roles.visible = true;

			foreach (API.AccountRole role in profile.account.roles) {
				roles.append (
					new Gtk.FlowBoxChild () {
						child = role.to_widget (),
						css_classes = { "profile-role-border-radius" }
					}
				);
			}
		}

		if (profile.account.id != accounts.active.id) {
			note_entry_row.notify["text"].connect (on_note_changed);
			profile.rs.invalidated.connect (on_rs_invalidation);
			rsbtn.handle = profile.account.handle;
			rsbtn.rs = profile.rs;
			rsbtn.visible = true;
		}

		if (profile.account.header.contains ("/headers/original/missing.png")) {
			header_url = "";
			background.paintable = avatar.custom_image;
		} else {
			header_url = profile.account.header ?? "";
			Tuba.Helper.Image.request_paintable (profile.account.header, null, false, on_cache_response);

			if (!mini)
				background.clicked.connect (open_header_in_media_viewer);
		}

		avi_url = profile.account.avatar ?? "";
		if (mini) {
			avatar.clicked.connect (on_avatar_clicked);
		} else {
			avatar.clicked.connect (open_pfp_in_media_viewer);
		}

		if (profile.account.fields != null || profile.account.created_at != null) {
			fields_box = new Gtk.FlowBox () {
				max_children_per_line = app.is_mobile ? 1 : 2,
				min_children_per_line = 1,
				selection_mode = Gtk.SelectionMode.NONE,
				css_classes = {"ttl-profile-fields-box"}
			};
			var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);
			total_fields = profile.account.fields.size;

			foreach (API.AccountField f in profile.account.fields) {
				var row = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
					css_classes = {"ttl-profile-field"}
				};
				var val = new Widgets.RichLabel (HtmlUtils.simplify (f.val)) {
					use_markup = true,
					xalign = 0,
					selectable = true
				};

				var title_label = new Widgets.EmojiLabel () {
					use_markup = false,
					css_classes = {"dim-label"}
				};
				title_label.instance_emojis = profile.account.emojis_map;
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

			if (profile.account.created_at != null) {
				total_fields += 1;
				var row = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
					css_classes = {"ttl-profile-field"}
				};
				var parsed_date = new GLib.DateTime.from_iso8601 (profile.account.created_at, null);
				parsed_date = parsed_date.to_timezone (new TimeZone.local ());

				var date_local = _("%B %e, %Y");
				var val = new Gtk.Label (parsed_date.format (date_local).replace (" ", "")) { // %e prefixes with whitespace on single digits
					wrap = true,
					xalign = 0,
					hexpand = true,
					tooltip_text = parsed_date.format ("%F")
				};

				var title_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
				// translators: as in created an account; this is used in Profiles in a row
				//				which has as value the date the profile was created on
				title_box.append (new Gtk.Label (_("Joined")) {
					css_classes = {"dim-label"}
				});
				title_box.prepend (new Gtk.Image.from_icon_name ("contact-new-symbolic"));
				row.append (title_box);
				row.append (val);

				fields_box.append (row);
				sizegroup.add_widget (row);
			}

			fields_box_row = new Gtk.ListBoxRow () {
				child = fields_box,
				activatable = false,
				css_classes = {"ttl-profile-fields-box-container"}
			};

			if (total_fields % 2 != 0) {
				fields_box_row.add_css_class ("odd");
			}

			if (total_fields == 1) {
				fields_box_row.add_css_class ("single");
			}

			info.append (fields_box_row);
			app.notify["is-mobile"].connect (update_fields_max_columns);
		}

		if (!mini) {
			build_profile_stats (profile.account);
			build_profile_filters ();
		} else {
			background.height_request = 64;

			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of posts a user has made.
			string posts_str = GLib.ngettext (
				"%s Post",
				"%s Posts",
				(ulong) profile.account.statuses_count
			).printf (@"<b>$(Tuba.Units.shorten (profile.account.statuses_count))</b>");

			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of followers a user has.
			string followers_str = GLib.ngettext (
				"%s Follower",
				"%s Followers",
				(ulong) profile.account.statuses_count
			).printf (@"<b>$(Tuba.Units.shorten (profile.account.followers_count))</b>");

			stats_string = "<span allow_breaks=\"false\">%s</span>   <span allow_breaks=\"false\">%s</span>   <span allow_breaks=\"false\">%s</span>".printf (
				posts_str,
				// translators: Used in profile stats.
				//              The variable is a shortened number of the amount of people a user follows.
				_("%s Following").printf (@"<b>$(Tuba.Units.shorten (profile.account.following_count))</b>"),
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

	protected void build_profile_stats (API.Account account) {
		var row = new Gtk.ListBoxRow ();
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

		// translators: Used in profile stats.
		//              The variable is a shortened number of the amount of posts a user has made.
		string posts_str = GLib.ngettext (
			"%s Post",
			"%s Posts",
			(ulong) account.statuses_count
		);

		// translators: Used in profile stats.
		//              The variable is a shortened number of the amount of followers a user has.
		string followers_str = GLib.ngettext (
			"%s Follower",
			"%s Followers",
			(ulong) account.statuses_count
		);

		var btn = build_profile_stats_button (posts_str.printf (Tuba.Units.shorten (account.statuses_count)));
		btn.tooltip_text = posts_str.printf (account.statuses_count.to_string ());
		btn.clicked.connect (() => timeline_change ("statuses"));
		sizegroup.add_widget (btn);
		box.append (btn);

		var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		// translators: Used in profile stats.
		//              The variable is a shortened number of the amount of people a user follows.
		btn = build_profile_stats_button (_("%s Following").printf (Tuba.Units.shorten (account.following_count)));
		btn.tooltip_text = _("%s Following").printf (account.following_count.to_string ());
		btn.clicked.connect (() => timeline_change ("following"));
		sizegroup.add_widget (btn);
		box.append (btn);

		separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		// translators: the variable is the amount of followers a user has
		btn = build_profile_stats_button (followers_str.printf (Tuba.Units.shorten (account.followers_count)));
		btn.tooltip_text = followers_str.printf (account.followers_count.to_string ());
		btn.clicked.connect (() => timeline_change ("followers"));
		sizegroup.add_widget (btn);
		box.append (btn);

		row.activatable = false;
		row.focusable = false;
		row.child = box;
		info.append (row);
	}

	protected void build_profile_filters () {
		var row = new Gtk.ListBoxRow ();
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
		var sizegroup = new Gtk.SizeGroup (Gtk.SizeGroupMode.HORIZONTAL);

		var btn = build_profile_stats_button (_("Posts"));
		box.append (btn);
		btn.clicked.connect (() => filter_change (Views.Profile.Filter.POSTS));
		sizegroup.add_widget (btn);

		var separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		btn = build_profile_stats_button (_("Replies"));
		btn.clicked.connect (() => filter_change (Views.Profile.Filter.REPLIES));
		box.append (btn);
		sizegroup.add_widget (btn);

		separator = new Gtk.Separator (Gtk.Orientation.VERTICAL);
		box.append (separator);

		btn = build_profile_stats_button (_("Media"));
		btn.clicked.connect (() => filter_change (Views.Profile.Filter.MEDIA));
		box.append (btn);
		sizegroup.add_widget (btn);

		row.activatable = false;
		row.focusable = false;
		row.child = box;
		info.append (row);
	}

	protected Gtk.Button build_profile_stats_button (string btn_label) {
		var btn = new Gtk.Button.with_label (btn_label) {
			css_classes = { "flat", "ttl-profile-stat-button" },
			hexpand = true
		};

		var child_label = btn.child as Gtk.Label;
		child_label.wrap = true;
		child_label.justify = Gtk.Justification.CENTER;

		return btn;
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
