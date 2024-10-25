[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/announcement.ui")]
public class Tuba.Widgets.Announcement : Gtk.ListBoxRow {
	public signal void open ();

	[GtkChild] protected unowned Adw.Avatar avatar;
	[GtkChild] protected unowned Widgets.RichLabel name_label;
	[GtkChild] protected unowned Gtk.Label handle_label;
	[GtkChild] protected unowned Gtk.Image edited_indicator;
	[GtkChild] protected unowned Gtk.Image attention_indicator;
	[GtkChild] protected unowned Gtk.Label date_label;
	[GtkChild] protected unowned Widgets.MarkupView content;
	[GtkChild] protected unowned Gtk.Box mainbox;

	private void aria_describe_status () {
		// translators: This is an accessibility label.
		//				Screen reader users are going to hear this a lot,
		//				please be mindful.
		//				The first variable is the instance's name and the
		//				second one is the instance's domain.
		string aria_post = _("Announcement by %s (%s).").printf (
			this.name_label.get_text (),
			this.handle_label.get_text ()
		);

		string aria_date = DateTime.humanize_aria (announcement_date);
		string aria_date_prefixed = edited_indicator.visible
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is a string date.
			? _("Edited: %s.").printf (aria_date)
			// translators: This is an accessibility label.
			//				Screen reader users are going to hear this a lot,
			//				please be mindful.
			//				The variable is a string date.
			: _("Published: %s.").printf (aria_date);

		string aria_reactions = "";
		if (reactions_count > 0) {
			aria_reactions = GLib.ngettext (
				// translators: This is an accessibility label.
				//				Screen reader users are going to hear this a lot,
				//				please be mindful.
				//				The variable is the amount of reactions the post
				//				has.
				"Contains %d reaction.", "Contains %d reactions.",
				(ulong) reactions_count
			).printf (reactions_count);
		}

		// translators: This is an accessibility label.
		//				Screen reader users are going to hear this a lot,
		//				please be mindful.
		//				This is used to indicate that the announcement
		//				hasn't been read yet.
		string aria_read = attention_indicator.visible ? _("Unread.") : "";

		this.update_property (
			Gtk.AccessibleProperty.LABEL,
			"%s %s %s %s".printf (
				aria_post,
				aria_date_prefixed,
				aria_read,
				aria_reactions
			),
			-1
		);
	}

	void settings_updated () {
		Tuba.toggle_css (this, settings.larger_font_size, "ttl-status-font-large");
		Tuba.toggle_css (this, settings.larger_line_height, "ttl-status-line-height-large");
		Tuba.toggle_css (this, settings.scale_emoji_hover, "lww-scale-emoji-hover");
	}

	static construct {
		typeof (Widgets.RichLabel).ensure ();
		typeof (Widgets.MarkupView).ensure ();
	}

	construct {
		edited_indicator.update_property (Gtk.AccessibleProperty.LABEL, edited_indicator.tooltip_text, -1);

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

	string announcement_date;
	int reactions_count = 0;
	public Announcement (API.Announcement t_announcement) {
		content.instance_emojis = t_announcement.emojis_map;
		content.content = t_announcement.content;
		attention_indicator.visible = !t_announcement.read;

		var instance_title = accounts.active.instance_info.title;
		var instance_thumbnail = accounts.active.instance_info.thumbnail;
		var instance_uri = accounts.active.instance_info.uri ?? accounts.active.domain;

		if (t_announcement.updated_at != null && t_announcement.updated_at != t_announcement.published_at) {
			announcement_date = t_announcement.updated_at;
			edited_indicator.visible = true;
		} else {
			announcement_date = t_announcement.published_at;
			edited_indicator.visible = false;
		}

		date_label.label = DateTime.humanize (announcement_date);
		date_label.tooltip_text = new GLib.DateTime.from_iso8601 (announcement_date, null).format ("%F %T");
		date_label.update_property (Gtk.AccessibleProperty.LABEL, date_label.tooltip_text, -1);

		handle_label.label = @"@$instance_uri";
		avatar.text = name_label.label = instance_title;
		if (instance_title != "") avatar.show_initials = true;
		if (instance_thumbnail != "") Tuba.Helper.Image.request_paintable (instance_thumbnail, null, false, on_cache_response);

		reactions_count = t_announcement.reactions.size;
		if (reactions_count > 0)
			mainbox.append (new Widgets.ReactionsRow (t_announcement.id, t_announcement.reactions, true) {
				margin_top = 16
			});

		t_announcement.bind_property ("read", attention_indicator, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		aria_describe_status ();
	}

	void on_cache_response (Gdk.Paintable? data) {
		avatar.custom_image = data;
	}
}
