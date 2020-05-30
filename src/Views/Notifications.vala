using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Timeline, IAccountListener, IStreamListener {

    protected int64 last_id = 0;
    protected bool force_dot = false;

    public Notifications () {
        Object ();
        on_notification.connect (add_notification);
    }

    public bool has_unread () {
        if (account == null)
            return false;
        return last_id > account.last_seen_notification || force_dot;
    }

    public override string get_icon () {
        if (has_unread ())
            return Desktop.fallback_icon ("notification-new-symbolic", "user-available-symbolic");
        else
            return Desktop.fallback_icon ("notification-symbolic", "user-invisible-symbolic");
    }

    public override string get_name () {
        return _("Notifications");
    }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.token)" : null;
    }

    public override string get_url () {
        if (page_next != null)
            return page_next;

        return "/api/v1/notifications";
    }

    public override void on_content_changed () {
        base.on_content_changed ();
        if (image != null && empty)
            image.icon_name = get_icon ();
    }

    public override void on_set_current () {
        if (has_unread ()) {
            force_dot = false;
            account.has_unread_notifications = force_dot;
            account.last_seen_notification = last_id;
            accounts.save ();
            image.icon_name = get_icon ();
        }
    }

    public override void append (Widget? w, bool reverse = false) {
        base.append (w, reverse);
        var nw = w as Widgets.Notification;
        var notification = nw.notification;

        if (reverse && !current) {
            force_dot = true;
            accounts.active.has_unread_notifications = force_dot;
        }

        if (notification.id > last_id)
            last_id = notification.id;

        if (has_unread ()) {
            accounts.save ();
            image.icon_name = get_icon ();
        }
    }

    public override GLib.Object? to_entity (Json.Object? json) {
    	if (json != null)
        	return new API.Notification (json);
        else
        	return null;
    }

    public override Widget? widgetize (GLib.Object? entity) {
        var n = entity as API.Notification;
        if (n == null)
            return null;

        var w = new Widgets.Notification (n);
        return w;
    }

    public override void on_account_changed (InstanceAccount? acc) {
        base.on_account_changed (acc);
        if (account == null) {
		    last_id = 0;
		    force_dot = false;
        }
        else {
		    last_id = account.last_seen_notification;
		    force_dot = account.has_unread_notifications;
		}
    }

    public override bool request () {
        if (account != null) {
            account.cached_notifications.@foreach (n => {
                append (widgetize (n));
                return true;
            });
        }
        return base.request ();
    }

    protected virtual void add_notification (API.Notification n) {
        prepend (widgetize (n));
    }

}
