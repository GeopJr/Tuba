using Gtk;
using Gdk;

public class Tootle.NotificationsView : AbstractView {

    public NotificationsView () {
        base ();
        
        view.remove.connect (on_remove);
        Tootle.accounts.switched.connect(on_account_changed);
        Tootle.app.refresh.connect(on_refresh);
        Tootle.network.notification.connect (prepend);
        
        request ();
    }
    
    public override string get_icon () {
        return "notification-symbolic";
    }
    
    public override string get_name () {
        return _("Notifications");
    }
    
    public void prepend (ref Notification notification) {
        append (ref notification, true);
    }
    
    public void append (ref Notification notification, bool reverse = false) {
        if (empty != null)
            empty.destroy ();
    
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();
        
        var widget = new NotificationWidget(notification);
        widget.separator = separator;
        image.icon_name = "notification-new-symbolic";
        view.pack_start(separator, false, false, 0);
        view.pack_start(widget, false, false, 0);
        
        if (reverse) {
            view.reorder_child (widget, 0);
            view.reorder_child (separator, 0);
        }
    }
    
    public virtual void on_remove (Widget widget) {
        if (!(widget is NotificationWidget))
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
        request ();
    }

    public virtual void on_account_changed (Account? account) {
        if(account == null)
            return;
        
        on_refresh ();
    }
    
    public void request () {
        if (accounts.current == null) {
            empty_state ();
            return;
        }
    
        var url = "%s/api/v1/follow_requests".printf (Tootle.accounts.formal.instance);
        var msg = new Soup.Message("GET", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                Tootle.network.parse_array (mess).foreach_element ((array, i, node) => {
                    var obj = node.get_object ();
                    if (obj != null){
                        var notification = Notification.parse_follow_request(obj);
                        append (ref notification);
                    }
                });
            }
            catch (GLib.Error e) {
                warning ("Can't update follow requests");
                warning (e.message);
            }
        });
    
        var url2 = "%s/api/v1/notifications?limit=30".printf (Tootle.accounts.formal.instance);
        var msg2 = new Soup.Message("GET", url2);
        Tootle.network.queue(msg2, (sess, mess) => {
            try{
                Tootle.network.parse_array (mess).foreach_element ((array, i, node) => {
                    var obj = node.get_object ();
                    if (obj != null){
                        var notification = Notification.parse(obj);
                        append (ref notification);
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
