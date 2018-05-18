using Gtk;
using Granite;

public class Tootle.NotificationWidget : Gtk.Grid {
    
    private Notification notification;

    public Gtk.Separator? separator;
    private Gtk.Image image;
    private Tootle.RichLabel label;
    private StatusWidget? status_widget;
    private Gtk.Button dismiss;

    construct {
        margin = 6;
        
        image = new Gtk.Image.from_icon_name("notification-symbolic", Gtk.IconSize.BUTTON);
        image.margin_start = 32;
        image.margin_end = 6;
        label = new RichLabel (_("Unknown Notification"));
        label.hexpand = true;
        label.halign = Gtk.Align.START;
        dismiss = new Gtk.Button.from_icon_name ("close-symbolic", Gtk.IconSize.BUTTON);
        dismiss.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        dismiss.tooltip_text = _("Dismiss");
        dismiss.clicked.connect (() => {
            notification.dismiss ();
            destroy ();
        });
        
        attach(image, 1, 2);
        attach(label, 2, 2);
        attach(dismiss, 3, 2);
        show_all();
    }

    public NotificationWidget (Notification notification) {
        this.notification = notification;
        image.icon_name = notification.type.get_icon ();
        label.label = notification.type.get_desc (notification.account);
        get_style_context ().add_class ("notification");
        
        if (notification.status != null) {
            Tootle.network.status_removed.connect (id => {
                if (id == notification.status.id)
                    destroy ();
            });
        }
        
        destroy.connect (() => {
            if(separator != null)
                separator.destroy ();
        });
        
        if (notification.status != null){
            status_widget = new StatusWidget (ref notification.status);
            status_widget.button_press_event.connect(status_widget.open);
            status_widget.avatar.button_press_event.connect(status_widget.on_avatar_clicked);
            attach(status_widget, 1, 3, 3, 1);
        }
        
        if (notification.type == NotificationType.FOLLOW_REQUEST) {
            var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            box.margin_start = 32 + 16 + 8;
            var accept = new Gtk.Button.with_label (_("Accept"));
            box.pack_start (accept, false, false, 0);
            var reject = new Gtk.Button.with_label (_("Reject"));
            box.pack_start (reject, false, false, 0);
            
            attach(box, 1, 3, 3, 1);
            box.show_all ();
            
            accept.clicked.connect (() => {
                destroy ();
                notification.accept_follow_request ();
            });
            reject.clicked.connect (() => {
                destroy ();
                notification.reject_follow_request ();
            });
        }
    }

}
