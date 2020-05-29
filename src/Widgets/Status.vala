using Gtk;
using Gdk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/widgets/status.ui")]
public class Tootle.Widgets.Status : EventBox {

    public API.Status status { get; construct set; }
    public API.NotificationType? kind { get; construct set; }

    [GtkChild]
    protected Separator separator;
    [GtkChild]
    protected Grid grid;

    [GtkChild]
    protected Image header_icon;
    [GtkChild]
    protected Widgets.RichLabel header_label;

    [GtkChild]
    public Widgets.Avatar avatar;
    [GtkChild]
    protected Widgets.RichLabel handle_label;
    [GtkChild]
    protected Label date_label;
    [GtkChild]
    protected Image pin_indicator;
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

    protected string escaped_spoiler {
        owned get {
            if (status.formal.has_spoiler) {
                var text = Html.simplify (status.formal.spoiler_text ?? "");
                var label = _("[ Toggle content ]");
                text += @" <a href='tootle://toggle'>$label</a>";
                return text;
            }
            else
                return Html.simplify (status.formal.content);
        }
    }

    protected string escaped_content {
        owned get {
            return status.formal.has_spoiler ? Html.simplify (status.formal.content) : "";
        }
    }

    protected string handle {
		owned get {
			var name = Html.simplify (status.formal.account.display_name);
			var handle = Html.simplify (status.formal.account.acct);
			return @"<b>$name</b> @$handle";
		}
	}

	protected string date {
		owned get {
		    var timeval = GLib.TimeVal ();
		    GLib.DateTime? date = null;
		    if (timeval.from_iso8601 (status.formal.created_at))
		        date = new GLib.DateTime.from_timeval_local (timeval);

		    return Granite.DateTime.get_relative_datetime (date);
		}
	}

    construct {
        button_press_event.connect (on_clicked);
        streams.status_removed.connect (on_status_removed);
        content.activate_link.connect (on_toggle_spoiler);
        notify["kind"].connect (on_kind_changed);

        if (kind == null) {
            if (status.reblog != null)
                kind = API.NotificationType.REBLOG_REMOTE_USER;
        }

        status.formal.bind_property ("favorited", favorite_button, "active", BindingFlags.SYNC_CREATE);
        favorite_button.clicked.connect (() => {
            status.action (status.formal.favorited ? "unfavourite" : "favourite");
        });

        status.formal.bind_property ("reblogged", reblog_button, "active", BindingFlags.SYNC_CREATE);
        reblog_button.clicked.connect (() => {
            status.action (status.formal.reblogged ? "unreblog" : "reblog");
        });

        reply_button.clicked.connect (() => new Dialogs.Compose.reply (status));

        bind_property ("escaped-spoiler", content, "label", BindingFlags.SYNC_CREATE);
        bind_property ("escaped-content", revealer_content, "label", BindingFlags.SYNC_CREATE);
        status.formal.account.bind_property ("avatar", avatar, "url", BindingFlags.SYNC_CREATE);
		bind_property ("handle", handle_label, "label", BindingFlags.SYNC_CREATE);
		bind_property ("date", date_label, "label", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("pinned", pin_indicator, "visible", BindingFlags.SYNC_CREATE);
		status.formal.bind_property ("replies-count", reply_button, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (((int64)src).to_string ());
			return true;
		});
		status.formal.bind_property ("reblogs-count", reblog_button, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (((int64)src).to_string ());
			return true;
		});
		status.bind_property ("favourites-count", favorite_button, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (((int64)src).to_string ());
			return true;
		});

        status.formal.bind_property ("has_spoiler", revealer_content, "visible", BindingFlags.SYNC_CREATE);
        revealer.reveal_child = !status.formal.has_spoiler;

        if (status.formal.visibility == API.Visibility.DIRECT) {
            reblog_icon.icon_name = status.formal.visibility.get_icon ();
            reblog_button.sensitive = false;
            reblog_button.tooltip_text = _("This post can't be boosted");
        }

        if (status.id <= 0) {
            actions.destroy ();
            date_label.destroy ();
            content.single_line_mode = true;
            content.lines = 2;
            content.ellipsize = Pango.EllipsizeMode.END;
            button_press_event.connect (on_avatar_clicked);
        }
        else {
            button_press_event.connect (open);
        }

        if (!attachments.populate (status.formal.attachments) || status.id <= 0) {
            attachments.destroy ();
        }
    }

    public Status (API.Status status, API.NotificationType? _kind = null) {
        Object (status: status, kind: _kind);
    }

    ~Status () {
        button_press_event.disconnect (on_clicked);
        streams.status_removed.disconnect (on_status_removed);
        notify["kind"].disconnect (on_kind_changed);
    }

	protected virtual void on_status_removed (int64 id) {
        if (id == status.id)
            destroy ();
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

    public bool on_avatar_clicked (EventButton ev) {
        if (ev.button == 1) {
            var view = new Views.Profile (status.formal.account);
            return window.open_view (view);
        }
        return false;
    }

    public bool open (EventButton ev) {
        if (ev.button == 1) {
            var formal = status.formal;
            var view = new Views.ExpandedStatus (formal);
            return window.open_view (view);
        }
        return false;
    }

    protected virtual bool on_clicked (EventButton ev) {
        if (ev.button == 3)
            return open_menu (ev.button, ev.time);
        return false;
    }

    public virtual bool open_menu (uint button, uint32 time) {
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

        if (status.is_owned ()) {
            var item_pin = new Gtk.MenuItem.with_label (status.pinned ? _("Unpin from Profile") : _("Pin on Profile"));
            item_pin.activate.connect (() => {
                status.action (status.formal.pinned ? "unpin" : "pin");
            });
            menu.add (item_pin);

            var item_delete = new Gtk.MenuItem.with_label (_("Delete"));
            item_delete.activate.connect (() => status.poof ());
            menu.add (item_delete);

            var item_redraft = new Gtk.MenuItem.with_label (_("Redraft"));
            item_redraft.activate.connect (() => new Dialogs.Compose.redraft (status.formal));
            menu.add (item_redraft);

            menu.add (new SeparatorMenuItem ());
        }

        // if (is_notification) {
        //     var item_muting = new Gtk.MenuItem.with_label (status.muted ? _("Unmute Conversation") : _("Mute Conversation"));
        //     item_muting.activate.connect (() => status.update_muted (!is_muted) );
        //     menu.add (item_muting);
        // }

        menu.add (item_open_link);
        menu.add (new SeparatorMenuItem ());
        menu.add (item_copy_link);
        menu.add (item_copy);

        menu.show_all ();
        menu.attach_widget = this;
        menu.popup_at_pointer ();
        return true;
    }

}
