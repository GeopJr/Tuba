using Gtk;
using Granite;

public class Tootle.NotificationWidget : Gtk.Grid {
    
    public Notification notification;

    public Gtk.Separator? separator;
    private Gtk.Image image;
    private Tootle.RichLabel label;
    private Gtk.Button dismiss_button;
    private StatusWidget? status_widget;

    construct {
        margin = 6;
        
        image = new Gtk.Image.from_icon_name("notification-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        image.margin_start = 32;
        image.margin_end = 6;
        label = new RichLabel (_("Unknown Notification"));
        label.hexpand = true;
        label.halign = Gtk.Align.START;
        dismiss_button = new Gtk.Button.from_icon_name ("close-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        dismiss_button.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        dismiss_button.tooltip_text = _("Dismiss");
        dismiss_button.clicked.connect (() => {
            var parent = this.get_parent () as Gtk.Box;
            parent.remove (this);
            dismiss (this.notification);
        });
        
        attach(image, 1, 2);
        attach(label, 2, 2);
        attach(dismiss_button, 3, 2);
        show_all();
    }

    public NotificationWidget (Notification notification) {
        this.notification = notification;
        image.icon_name = notification.type.get_icon ();
        label.label = notification.type.get_desc (notification.account);
        get_style_context ().add_class ("notification");
        
        if (notification.status != null){
            status_widget = new StatusWidget (this.notification.status);
            status_widget.rebind (this.notification.status);
            status_widget.button_press_event.connect(status_widget.open);
            status_widget.avatar.button_press_event.connect(status_widget.on_avatar_clicked);
            attach(status_widget, 1, 3, 3, 1);
        }
        
        destroy.connect (() => {
            if(separator != null)
                separator.destroy ();
        });
    }
    
    public static Soup.Message dismiss (Notification notification){
        var url = Tootle.settings.instance_url;
        url += "api/v1/notifications/dismiss";
        url += "?id=" + notification.id.to_string ();
        
        var msg = new Soup.Message("POST", url);
        Tootle.network.queue(msg, (sess, mess) => {});
        return msg;
    }

}
