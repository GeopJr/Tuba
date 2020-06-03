using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Timeline, IAccountListener, IStreamListener {

    protected int64 last_id = 0;

    public Notifications () {
        Object (
            url: "/api/v1/notifications",
        	label: _("Notifications"),
        	icon: Desktop.fallback_icon ("notification-symbolic", "preferences-system-notifications-symbolic", "user-invisible-symbolic")
        );
        on_notification.connect (add_notification);
        on_status_added.disconnect (add_status);
    }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.token)" : null;
    }

    public override void on_shown () {
        if (has_unread ()) {
            needs_attention = false;
            account.has_unread_notifications = false;
            account.last_seen_notification = last_id;
            accounts.save ();
        }
    }

    public override void append (Widget? w, bool reverse = false) {
        base.append (w, reverse);
        var nw = w as Widgets.Notification;
        var notification = nw.notification;

        if (notification.id > last_id)
            last_id = notification.id;

		needs_attention = has_unread () && !current;
        if (needs_attention)
            accounts.save ();
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
		    needs_attention = false;
        }
        else {
		    last_id = account.last_seen_notification;
		    needs_attention = account.has_unread_notifications;
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

    bool has_unread () {
        if (account == null)
            return false;
        return last_id > account.last_seen_notification || needs_attention;
    }

    void add_notification (API.Notification n) {
        prepend (widgetize (n));
    }

}
