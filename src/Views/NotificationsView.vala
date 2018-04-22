using Gtk;
using Gdk;

public class Tootle.NotificationsView : Tootle.AbstractView {

    Gtk.Box view;
    Gtk.ScrolledWindow scroll;

    construct {
        view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        view.hexpand = true;
        view.valign = Gtk.Align.START;

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hexpand = true;
        scroll.vexpand = true;
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.add (view);
        add (scroll);
    }

    public NotificationsView () {
        base (true);
        show_all();
        
        view.remove.connect (on_remove);
        AccountManager.instance.switched.connect(on_account_changed);
    }
    
    public override string get_icon () {
        return "notification-symbolic";
    }
    
    public override string get_name () {
        return "Notifications";
    }
    
    public void prepend(Notification notification){
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();
        
        var widget = new NotificationWidget(notification);
        widget.separator = separator;
        view.pack_start(separator, false, false, 0);
        view.pack_start(widget, false, false, 0);
        image.icon_name = "notification-new-symbolic";
    }
    
    public virtual void on_remove (Widget widget){
        if (!(widget is NotificationWidget))
            return;

        if (view.get_children ().length () <= 1)
            image.icon_name = get_icon ();
    }
    
    public virtual void on_account_changed (Account? account){
        if(account == null)
            return;
        
        var url = Settings.instance.instance_url;
        url += "/api/v1/notifications";
        
        var msg = new Soup.Message("GET", url);
        NetManager.instance.queue(msg, (sess, mess) => {
            try{
                NetManager.parse_array (mess).foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null){
                        var notification = Notification.parse(object);
                        prepend (notification);
                    }
                });
            }
            catch (GLib.Error e) {
                warning ("Can't update feed");
                warning (e.message);
            }
        });
    }

}
