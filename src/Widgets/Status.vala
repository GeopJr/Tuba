using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/status.ui")]
public class Tootle.Widgets.Status : ListBoxRow {

	public API.Status status { get; construct set; }
	public API.NotificationType? kind { get; construct set; }

	[GtkChild]
	protected Grid grid;

	[GtkChild]
	protected Image header_icon;
	[GtkChild]
	protected Widgets.RichLabel header_label;

	[GtkChild]
	public Widgets.Avatar avatar;
	[GtkChild]
	protected Widgets.RichLabel name_label;
	[GtkChild]
	protected Widgets.RichLabel handle_label;
	[GtkChild]
	protected Box indicators;
	[GtkChild]
	protected Widgets.RichLabel date_label;
	[GtkChild]
	protected Image pin_indicator;
	[GtkChild]
	protected Image indicator;
	[GtkChild]
	public Revealer revealer;
	[GtkChild]
	protected Widgets.RichLabel content;
	[GtkChild]
	protected Widgets.RichLabel revealer_content;
	[GtkChild]
	protected Widgets.Attachment.Box attachments;

	[GtkChild]
	protected Box actions;
	[GtkChild]
	protected Button reply_button;
	[GtkChild]
	protected ToggleButton reblog_button;
	[GtkChild]
	protected Image reblog_icon;
	[GtkChild]
	protected ToggleButton favorite_button;
	[GtkChild]
	protected ToggleButton bookmark_button;
	[GtkChild]
	protected Button menu_button;

	protected string escaped_spoiler {
		owned get {
			if (status.formal.has_spoiler) {
				var text = status.formal.spoiler_text ?? "";
				var label = _("[ Toggle content ]");
				text += @" <a href=\"tootle://toggle\">$label</a>";
				return text;
			}
			else
				return status.formal.content;
		}
	}

	protected string escaped_content {
		owned get {
			return status.formal.has_spoiler ? status.formal.content : "";
		}
	}

	protected string date {
		owned get {
			var date = status.formal.created_at;
			return @"<small>$(DateTime.humanize (date))</small>";
		}
	}

	public string title_text {
		owned get {
			var name = Html.simplify (status.formal.account.display_name);
			return @"<b>$name</b>";
		}
	}

	public string subtitle_text {
		owned get {
			return @"<small>$(status.formal.account.handle)</small>";
		}
	}

	public string? avatar_url {
		owned get {
			return status.formal.account.avatar;
		}
	}

	public signal void open ();

	public virtual void on_open () {
		if (status.id == "")
			on_avatar_clicked ();
		else
			status.open ();
	}

	construct {
		content.activate_link.connect (on_toggle_spoiler);
		notify["kind"].connect (on_kind_changed);
		open.connect (on_open);

		if (kind == null) {
			if (status.reblog != null)
				kind = API.NotificationType.REBLOG_REMOTE_USER;
		}

		status.formal.bind_property ("favourited", favorite_button, "active", BindingFlags.SYNC_CREATE);
		favorite_button.clicked.connect (() => {
			status.action (status.formal.favourited ? "unfavourite" : "favourite");
		});

		status.formal.bind_property ("reblogged", reblog_button, "active", BindingFlags.SYNC_CREATE);
		reblog_button.clicked.connect (() => {
			status.action (status.formal.reblogged ? "unreblog" : "reblog");
		});

		status.formal.bind_property ("bookmarked", bookmark_button, "active", BindingFlags.SYNC_CREATE);
		bookmark_button.clicked.connect (() => {
			status.action (status.formal.bookmarked ? "unbookmark" : "bookmark");
		});

		reply_button.clicked.connect (() => new Dialogs.Compose.reply (status));

		bind_property ("escaped-spoiler", content, "text", BindingFlags.SYNC_CREATE);
		bind_property ("escaped-content", revealer_content, "text", BindingFlags.SYNC_CREATE);
		bind_property ("title_text", name_label, "text", BindingFlags.SYNC_CREATE);
		bind_property ("subtitle_text", handle_label, "text", BindingFlags.SYNC_CREATE);
		bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		bind_property ("avatar_url", avatar, "url", BindingFlags.SYNC_CREATE);

		status.formal.bind_property ("has_spoiler", revealer_content, "visible", BindingFlags.SYNC_CREATE);
		revealer.reveal_child = !status.formal.has_spoiler;

		if (status.formal.visibility == API.Visibility.DIRECT) {
			reblog_icon.icon_name = status.formal.visibility.get_icon ();
			reblog_button.sensitive = false;
			reblog_button.tooltip_text = _("This post can't be boosted");
		}

		if (status.id == "") {
			actions.destroy ();
			date_label.destroy ();
			content.single_line_mode = true;
			content.lines = 2;
			content.ellipsize = Pango.EllipsizeMode.END;
		}

		if (!attachments.populate (status.formal.media_attachments) || status.id == "") {
			attachments.destroy ();
		}

		menu_button.clicked.connect (open_menu);
	}

	public Status (API.Status status, API.NotificationType? _kind = null) {
		Object (status: status, kind: _kind);
	}
	~Status () {
		notify["kind"].disconnect (on_kind_changed);
	}

	protected bool on_toggle_spoiler (string uri) {
		if (uri == "tootle://toggle") {
			revealer.reveal_child = !revealer.reveal_child;
			return true;
		}
		return false;
	}

	protected virtual void on_kind_changed () {
		header_icon.visible = header_label.visible = (kind != null);
		if (kind == null)
			return;

		header_icon.icon_name = kind.get_icon ();
		header_label.label = kind.get_desc (status.account);
	}

	[GtkCallback]
	public void on_avatar_clicked () {
		status.formal.account.open ();
	}

	protected void open_menu () {
		var menu = new Gtk.Menu ();

		var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
		item_open_link.activate.connect (() => Desktop.open_uri (status.formal.url));
		var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
		item_copy_link.activate.connect (() => Desktop.copy (status.formal.url));
		var item_copy = new Gtk.MenuItem.with_label (_("Copy Text"));
		item_copy.activate.connect (() => {
			var sanitized = Html.remove_tags (status.formal.content);
			Desktop.copy (sanitized);
		});

		// if (is_notification) {
		//	 var item_muting = new Gtk.MenuItem.with_label (status.muted ? _("Unmute Conversation") : _("Mute Conversation"));
		//	 item_muting.activate.connect (() => status.update_muted (!is_muted) );
		//	 menu.add (item_muting);
		// }

		menu.add (item_open_link);
		menu.add (new SeparatorMenuItem ());
		menu.add (item_copy_link);
		menu.add (item_copy);

		if (status.is_owned ()) {
			menu.add (new SeparatorMenuItem ());

			var item_pin = new Gtk.MenuItem.with_label (status.pinned ? _("Unpin from Profile") : _("Pin on Profile"));
			item_pin.activate.connect (() => {
				status.action (status.formal.pinned ? "unpin" : "pin");
			});
			menu.add (item_pin);

			var item_delete = new Gtk.MenuItem.with_label (_("Delete"));
			item_delete.activate.connect (() => {
				status.annihilate ()
					.then ((sess, mess) => {
						streams.force_delete (status.id);
					})
					.exec ();
			});
			menu.add (item_delete);

			var item_redraft = new Gtk.MenuItem.with_label (_("Redraft"));
			item_redraft.activate.connect (() => new Dialogs.Compose.redraft (status.formal));
			menu.add (item_redraft);
		}

		menu.show_all ();
		menu.popup_at_widget (menu_button, Gravity.SOUTH_EAST, Gravity.SOUTH_EAST);
	}

}
