using Gtk;
using Gdk;

public class Tootle.Views.Notifications : Views.Abstract {

    private int64 last_id = 0;
    private bool force_dot = false;

    public Notifications () {
        base ();
        view.remove.connect (on_remove);
        accounts.switched.connect (on_account_changed);
        app.refresh.connect (on_refresh);
        network.notification.connect (prepend);

        request ();
    }

    private bool has_unread () {
        var account = accounts.formal;
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
        if (empty != null)
            empty.destroy ();

        var separator = new Separator (Orientation.HORIZONTAL);
        separator.show ();

        var widget = new Widgets.Notification (notification);
        widget.separator = separator;
        view.pack_start (separator, false, false, 0);
        view.pack_start (widget, false, false, 0);

        if (reverse) {
            view.reorder_child (widget, 0);
            view.reorder_child (separator, 0);

            if (!current) {
                force_dot = true;
                accounts.formal.has_unread_notifications = force_dot;
            }
        }

        if (notification.id > last_id)
            last_id = notification.id;

        if (has_unread ()) {
            accounts.save ();
            image.icon_name = get_icon ();
        }
    }

    public override void on_set_current () {
        var account = accounts.formal;
        if (has_unread ()) {
            force_dot = false;
            account.has_unread_notifications = force_dot;
            account.last_seen_notification = last_id;
            accounts.save ();
            image.icon_name = get_icon ();
        }
    }

    public virtual void on_remove (Widget widget) {
        if (!(widget is Widgets.Notification))
            return;

        empty_state ();
    }

    public override bool empty_state () {
        var is_empty = base.empty_state ();
        if (image != null && is_empty)
            image.icon_name = get_icon ();

        return is_empty;
    }

    public virtual void on_refresh () {
        clear ();
        accounts.formal.cached_notifications.@foreach (notification => {
            append (notification);
            return true;
        });
        request ();
    }

    public virtual void on_account_changed (API.Account? account) {
        if (account == null)
            return;

        last_id = accounts.formal.last_seen_notification;
        force_dot = accounts.formal.has_unread_notifications;
        on_refresh ();
    }

    public void request () {
        if (accounts.current == null) {
            empty_state ();
            return;
        }

        var url = "%s/api/v1/follow_requests".printf (accounts.formal.instance);
        var msg = new Soup.Message ("GET", url);
        network.queue (msg, (sess, mess) => {
            try {
                network.parse_array (mess).foreach_element ((array, i, node) => {
                    var obj = node.get_object ();
                    if (obj != null){
                        var notification = API.Notification.parse_follow_request (obj);
                        append (notification);
                    }
                });
            }
            catch (GLib.Error e) {
                warning ("Can't update follow requests");
                warning (e.message);
            }
        });

        var url2 = "%s/api/v1/notifications?limit=30".printf (accounts.formal.instance);
        var msg2 = new Soup.Message ("GET", url2);
        network.queue (msg2, (sess, mess) => {
            try {
                network.parse_array (mess).foreach_element ((array, i, node) => {
                    var obj = node.get_object ();
                    if (obj != null){
                        var notification = API.Notification.parse (obj);
                        append (notification);
                    }
                });
            }
            catch (GLib.Error e) {
                warning ("Can't update notifications");
                warning (e.message);
            }
        });

        empty_state ();
    }

}
