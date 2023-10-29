[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/announcement.ui")]
public class Tuba.Widgets.Announcement : Gtk.ListBoxRow {
	public class ReactButton : Gtk.Button {
		private Gtk.Label reactions_label;
		public string shortcode { get; private set; }
		public signal void reaction_toggled ();

		private bool _has_reacted = false;
		public bool has_reacted {
			get {
				return _has_reacted;
			}
			set {
				_has_reacted = value;
				update_reacted (value);
			}
		}

		private int64 _reactions = 0;
		public int64 reactions {
			get {
				return _reactions;
			}
			set {
				_reactions = value;
				reactions_label.label = value.to_string ();
			}
		}

		public ReactButton (API.EmojiReaction reaction) {
			// translators: the variable is the emoji or its name if it's custom
			tooltip_text = _("React with %s").printf (reaction.name);
			shortcode = reaction.name;

			var badge = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
			if (reaction.url != null) {
				badge.append (new Widgets.Emoji (reaction.url));
			} else {
				badge.append (new Gtk.Label (reaction.name));
			}

			reactions_label = new Gtk.Label (null);
			reactions = reaction.count;

			badge.append (reactions_label);
			this.child = badge;

			_has_reacted = reaction.me;
			if (reaction.me == true) {
				this.add_css_class ("accent");
			}

			this.clicked.connect (on_clicked);
		}

		public void update_reacted (bool reacted = true) {
			if (reacted) {
				this.add_css_class ("accent");
				reactions = reactions + 1;
			} else {
				this.remove_css_class ("accent");
				reactions = reactions - 1;
			}
			_has_reacted = reacted;
		}

		private void on_clicked () {
			reaction_toggled ();
		}
	}

	private API.Announcement announcement { get; private set; }
	public signal void open ();

	[GtkChild] protected unowned Adw.Avatar avatar;
	[GtkChild] protected unowned Widgets.RichLabel name_label;
	[GtkChild] protected unowned Gtk.Label handle_label;
	[GtkChild] protected unowned Gtk.Image edited_indicator;
	[GtkChild] protected unowned Gtk.Image attention_indicator;
	[GtkChild] protected unowned Gtk.Label date_label;
	[GtkChild] protected unowned Widgets.MarkupView content;
	[GtkChild] protected unowned Gtk.FlowBox emoji_reactions;

	private Gee.ArrayList<API.EmojiReaction>? reactions {
		set {
			if (value == null) return;

			var i = 0;
			Gtk.FlowBoxChild? fb_child = null;
			while ((fb_child = emoji_reactions.get_child_at_index (i)) != null) {
				emoji_reactions.remove (fb_child);
				i = i + 1;
			}

			foreach (API.EmojiReaction p in value) {
				if (p.count <= 0) return;

				var badge_button = new ReactButton (p);
				badge_button.reaction_toggled.connect (on_reaction_toggled);

				//  emoji_reactions.append(badge_button); // GTK >= 4.5
				emoji_reactions.insert (badge_button, -1);
			}

			emoji_reactions.visible = value.size > 0;
		}
	}

	void settings_updated () {
		Tuba.toggle_css (this, settings.larger_font_size, "ttl-status-font-large");
		Tuba.toggle_css (this, settings.larger_line_height, "ttl-status-line-height-large");
		Tuba.toggle_css (this, settings.scale_emoji_hover, "lww-scale-emoji-hover");
	}

	construct {
		if (settings.larger_font_size)
			add_css_class ("ttl-status-font-large");

		if (settings.larger_line_height)
			add_css_class ("ttl-status-line-height-large");

		if (settings.scale_emoji_hover)
			add_css_class ("lww-scale-emoji-hover");

		settings.notify["larger-font-size"].connect (settings_updated);
		settings.notify["larger-line-height"].connect (settings_updated);
		settings.notify["scale-emoji-hover"].connect (settings_updated);
	}

    public Announcement (API.Announcement t_announcement) {
		announcement = t_announcement;

		content.instance_emojis = t_announcement.emojis_map;
		content.content = t_announcement.content;
		attention_indicator.visible = !t_announcement.read;

		var instance_title = accounts.active.instance_info.title;
		var instance_thumbnail = accounts.active.instance_info.thumbnail;
		var instance_uri = accounts.active.instance_info.uri ?? accounts.active.domain;
		string announcement_date;

		if (t_announcement.updated_at != null && t_announcement.updated_at != t_announcement.published_at) {
			announcement_date = t_announcement.updated_at;
			edited_indicator.visible = true;
		} else {
			announcement_date = t_announcement.published_at;
			edited_indicator.visible = false;
		}
		date_label.label = DateTime.humanize (announcement_date);

		handle_label.label = @"@$instance_uri";
		avatar.text = name_label.label = instance_title;
		if (instance_title != "") avatar.show_initials = true;
		if (instance_thumbnail != "") Tuba.Helper.Image.request_paintable (instance_thumbnail, null, on_cache_response);

		reactions = t_announcement.reactions;

		announcement.bind_property ("read", attention_indicator, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
	}

	void on_cache_response (Gdk.Paintable? data) {
		avatar.custom_image = data;
	}

	private void on_reaction_toggled (ReactButton btn) {
		var endpoint = @"/api/v1/announcements/$(announcement.id)/reactions/$(btn.shortcode)";
		var req = btn.has_reacted ? new Request.DELETE (endpoint) : new Request.PUT (endpoint);

		btn.sensitive = false;
		req
			.with_account (accounts.active)
			.then (() => {
				btn.update_reacted (!btn.has_reacted);
				btn.sensitive = true;
			})
			.on_error ((code, message) => {
				warning (@"Error while reacting to announcement: $code $message");
				btn.sensitive = true;

				var dlg = app.inform (_("Error"), message);
				dlg.present ();
			})
			.exec ();
	}
}
