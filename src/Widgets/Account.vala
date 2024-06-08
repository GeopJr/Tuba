[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/profile.ui")]
public class Tuba.Widgets.Account : Gtk.ListBoxRow {
	~Account () {
		debug ("Destroying Widgets.Account");
	}

	public class RelationshipButton : Tuba.Widgets.RelationshipButton {
		public override void invalidate () {
			if (rs == null || rs.domain_blocking) {
				visible = false;
				return;
			}
			visible = true;

			base.invalidate ();
		}
	}

	public bool disable_profile_open {
		set {
			if (value == true) {
				this.activatable = false;
				grid.can_focus = false;
				grid.focusable = false;
				grid.can_target = false;
				if (open_signal != -1) this.disconnect (open_signal);
			}
		}
	}

	[GtkChild] unowned Widgets.Background background;
	[GtkChild] unowned Gtk.Overlay cover_overlay;
	[GtkChild] unowned Gtk.Label cover_badge;
	[GtkChild] unowned Gtk.Image cover_bot_badge;
	[GtkChild] unowned Gtk.Box cover_badge_box;
	[GtkChild] unowned Widgets.EmojiLabel display_name;
	[GtkChild] unowned Gtk.Label handle;
	[GtkChild] unowned Gtk.Label stats_label;
	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Widgets.MarkupView note;
	[GtkChild] unowned RelationshipButton rsbtn;
	[GtkChild] unowned Gtk.Grid grid;
	public signal void open ();

	public API.Relationship rs {
		set {
			rsbtn.rs = value;

			if (value.tuba_has_loaded) {
				cover_badge_label = rsbtn.rs.to_string ();
			} else {
				invalidate_signal_id = rsbtn.rs.invalidated.connect (on_rs_invalidate);
			}

			update_aria ();
		}
	}

	ulong invalidate_signal_id = 0;
	private void on_rs_invalidate () {
		cover_badge_label = rsbtn.rs.to_string ();
		rsbtn.rs.disconnect (invalidate_signal_id);
		update_aria ();
	}

	public string additional_label {
		set {
			cover_overlay.add_overlay (new Gtk.Label (value) {
				xalign = 0.0f,
				css_classes = {"cover-badge", "osd", "badge", "heading"},
				halign = Gtk.Align.START,
				valign = Gtk.Align.START,
			});
		}
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

	void toggle_scale_emoji_hover () {
		Tuba.toggle_css (note, settings.scale_emoji_hover, "lww-scale-emoji-hover");
	}

	void on_cache_response (Gdk.Paintable? data) {
		background.paintable = data;
	}

	private void update_aria () {
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

		string final_aria = "%s %s %s.".printf (
			aria_profile,
			aria_relationship,
			stats_label.get_text ()
		);

		this.update_property (
			Gtk.AccessibleProperty.LABEL,
			final_aria,
			-1
		);
	}

	private weak API.Account api_account { get; set; }
	private string account_id = "";
	private ulong open_signal = -1;
	public Account (API.Account account) {
		account_id = account.id;
		open.connect (account.open);
		background.clicked.connect (account.open);
		avatar.clicked.connect (account.open);

		if (settings.scale_emoji_hover)
			note.add_css_class ("lww-scale-emoji-hover");
		settings.notify["scale-emoji-hover"].connect (toggle_scale_emoji_hover);

		display_name.instance_emojis = account.emojis_map;
		display_name.content = account.display_name;
		handle.label = account.handle;
		avatar.account = account;
		note.instance_emojis = account.emojis_map;
		note.content = account.note;
		cover_bot_badge.visible = account.bot;

		rsbtn.handle = account.handle;

		if (account.tuba_rs != null)
			rs = account.tuba_rs;

		api_account = account;
		api_account.notify["tuba-rs"].connect (on_tuba_rs);

		if (account.header.contains ("/headers/original/missing.png")) {
			background.paintable = avatar.custom_image;
		} else {
			Tuba.Helper.Image.request_paintable (account.header, null, on_cache_response);
		}

		// translators: Used in profile stats.
		//              The variable is a shortened number of the amount of posts a user has made.
		string posts_str = GLib.ngettext (
			"%s Post",
			"%s Posts",
			(ulong) account.statuses_count
		).printf (@"<b>$(Tuba.Units.shorten (account.statuses_count))</b>");

		// translators: Used in profile stats.
		//              The variable is a shortened number of the amount of followers a user has.
		string followers_str = GLib.ngettext (
			"%s Follower",
			"%s Followers",
			(ulong) account.statuses_count
		).printf (@"<b>$(Tuba.Units.shorten (account.followers_count))</b>");

		stats_label.label = "<span allow_breaks=\"false\">%s</span>   <span allow_breaks=\"false\">%s</span>   <span allow_breaks=\"false\">%s</span>".printf (
			posts_str,
			// translators: Used in profile stats.
			//              The variable is a shortened number of the amount of people a user follows.
			_("%s Following").printf (@"<b>$(Tuba.Units.shorten (account.following_count))</b>"),
			followers_str
		);

		update_aria ();
	}

	private void on_tuba_rs () {
		if (api_account != null)
			rs = api_account.tuba_rs;
	}

	public Widgets.FollowRequestRow add_fr_row () {
		var fr_row = new Widgets.FollowRequestRow (account_id) {
			margin_top = 6,
			margin_bottom = 6
		};
		grid.attach (fr_row, 0, 5, 2, 1);
		return fr_row;
	}
}
