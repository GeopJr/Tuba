using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Base, IAccountListener, IStreamListener { //TODO: make this a timeline

    protected InstanceAccount? account = null;
    protected int64 last_id = 0;
    protected bool force_dot = false;

    protected string? stream;

    public Notifications () {
        app.refresh.connect (on_refresh);
        status_button.clicked.connect (on_refresh);
        connect_account ();
    }
    ~Notifications () {
        streams.unsubscribe (stream, this);
    }

    private bool has_unread () {
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

    public void prepend (API.Notification notification) {
        append (notification, true);
    }

    public void append (API.Notification notification, bool reverse = false) {
        GLib.Idle.add (() => {
            var widget = new Widgets.Notification (notification);
            content.pack_start (widget, false, false, 0);

            if (reverse) {
                content.reorder_child (widget, 0);

                if (!current) {
                    force_dot = true;
                    accounts.active.has_unread_notifications = force_dot;
                }
            }

            on_content_changed ();

            if (notification.id > last_id)
                last_id = notification.id;

            if (has_unread ()) {
                accounts.save ();
                image.icon_name = get_icon ();
            }
            return GLib.Source.REMOVE;
        });
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

    public override void on_content_changed () {
        base.on_content_changed ();
        if (image != null && empty)
            image.icon_name = get_icon ();
    }

    public virtual void on_refresh () {
        clear ();
        GLib.Idle.add (request);
    }

    public virtual void on_account_changed (InstanceAccount? acc) {
        account = acc;
		streams.unsubscribe (stream, this);
        if (account == null) {
		    last_id = 0;
		    force_dot = false;
        }
        else {
		    last_id = account.last_seen_notification;
		    force_dot = account.has_unread_notifications;
		    streams.subscribe (get_stream_url (), this, out stream);
		}
		on_refresh ();
    }

    public virtual string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.token)" : null;
    }

    public override bool accepts (ref string event) {
		return true;
	}

    public override void on_notification (API.Notification n) {
        prepend (n);
    }

    public bool request () {
        if (account != null) {
            account.cached_notifications.@foreach (notification => {
                append (notification);
                return true;
            });
        }

        // new Request.GET ("/api/v1/follow_requests")  //TODO: this
        // 	.with_account ()
        // 	.then_parse_array (node => {
        //   var notification = API.Notification.parse_follow_request (node.get_object ());
        //   append (notification);
        // 	})
        // 	.on_error (on_error)
        // 	.exec ();

        new Request.GET ("/api/v1/notifications")
        	.with_account (account)
        	.with_param ("limit", "30")
        	.then_parse_array (node => {
				var notification = new API.Notification (node.get_object ());
				append (notification);
        	})
        	.on_error (on_error)
        	.exec ();

        return GLib.Source.REMOVE;
    }

}
