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

	[GtkChild] unowned Widgets.Background background;
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
		}
	}

	ulong invalidate_signal_id = 0;
	private void on_rs_invalidate () {
		cover_badge_label = rsbtn.rs.to_string ();
		rsbtn.rs.disconnect (invalidate_signal_id);
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

	private weak API.Account api_account { get; set; }
	private string account_id = "";
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
