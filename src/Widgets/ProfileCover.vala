[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/profile_header.ui")]
protected class Tuba.Widgets.Cover : Gtk.Box {

    [GtkChild] unowned Gtk.FlowBox roles;
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

    public API.Relationship rs { get; construct set; }
    public signal void rs_invalidated ();
    public signal void timeline_change (string timeline);

    ~Cover () {
        debug ("Destroying Profile Cover");
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
        app.main_window.show_media_viewer (header_url, Tuba.Attachment.MediaType.IMAGE, background.paintable, null, background, true);
    }

    void open_pfp_in_media_viewer () {
        app.main_window.show_media_viewer (avi_url, Tuba.Attachment.MediaType.IMAGE, avatar.custom_image, null, avatar, true);
    }

    public Cover (Views.Profile.ProfileAccount profile) {
        if (settings.scale_emoji_hover)
            note.add_css_class ("lww-scale-emoji-hover");
        settings.notify["scale-emoji-hover"].connect (toggle_scale_emoji_hover);

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
            profile.rs.invalidated.connect (() => {
                cover_badge_label = profile.rs.to_string ();
                rs_invalidated ();
            });

            rsbtn.rs = profile.rs;
            rsbtn.visible = true;
        }

        if (profile.account.header.contains ("/headers/original/missing.png")) {
            header_url = "";
            background.paintable = avatar.custom_image;
        } else {
            header_url = profile.account.header ?? "";
            Tuba.Helper.Image.request_paintable (profile.account.header, null, on_cache_response);
            background.clicked.connect (open_header_in_media_viewer);
        }

        avi_url = profile.account.avatar ?? "";
        avatar.clicked.connect (open_pfp_in_media_viewer);

        if (profile.account.fields != null) {
            foreach (API.AccountField f in profile.account.fields) {
                var row = new Adw.ActionRow ();
                var val = new Widgets.RichLabel (HtmlUtils.simplify (f.val)) {
                    use_markup = true,
                    hexpand = true,
                    xalign = 1
                };
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

        if (profile.account.created_at != null) {
            var row = new Adw.ActionRow ();
            var parsed_date = new GLib.DateTime.from_iso8601 (profile.account.created_at, null);
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
            row.add_prefix (new Gtk.Image.from_icon_name ("contact-new-symbolic"));
        }

        build_profile_stats (profile.account);
    }

    protected void build_profile_stats (API.Account account) {
		var row = new Gtk.ListBoxRow ();
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0) {
			homogeneous = true
		};

		// translators: the variable is the amount of posts a user has made
		var btn = build_profile_stats_button (_("%s Posts").printf (Tuba.Units.shorten (account.statuses_count)));
		btn.clicked.connect (() => timeline_change ("statuses"));
		box.append (btn);

		// translators: the variable is the amount of people a user follows
		btn = build_profile_stats_button (_("%s Following").printf (Tuba.Units.shorten (account.following_count)));
		btn.clicked.connect (() => timeline_change ("following"));
		box.append (btn);

		// translators: the variable is the amount of followers a user has
		btn = build_profile_stats_button (_("%s Followers").printf (Tuba.Units.shorten (account.followers_count)));
		btn.clicked.connect (() => timeline_change ("followers"));
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

    void on_cache_response (owned Gdk.Paintable? data) {
        background.paintable = data;
    }
}
