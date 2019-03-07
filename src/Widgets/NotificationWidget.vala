using Gtk;
using Granite;

public class Tootle.NotificationWidget : Grid {

    private Notification notification;

    public Separator? separator;
    private Image image;
    private RichLabel label;
    private StatusWidget? status_widget;
    private Button dismiss;

    construct {
        margin = 6;

        image = new Image.from_icon_name ("notification-symbolic", IconSize.BUTTON);
        image.margin_start = 32;
        image.margin_end = 6;
        label = new RichLabel (_("Unknown Notification"));
        label.hexpand = true;
        label.halign = Align.START;
        dismiss = new Button.from_icon_name ("close-symbolic", IconSize.BUTTON);
        dismiss.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        dismiss.tooltip_text = _("Dismiss");
        dismiss.clicked.connect (() => {
            notification.dismiss ();
            destroy ();
        });

        attach (image, 1, 2);
        attach (label, 2, 2);
        attach (dismiss, 3, 2);
        show_all ();
    }

    public NotificationWidget (Notification _notification) {
        notification = _notification;
        image.icon_name = notification.type.get_icon ();
        label.set_label (notification.type.get_desc (notification.account));
        get_style_context ().add_class ("notification");

        if (notification.status != null)
            network.status_removed.connect (on_status_removed);

        destroy.connect (() => {
            if (separator != null)
                separator.destroy ();
            separator = null;
            status_widget = null;
        });

        if (notification.status != null){
            status_widget = new StatusWidget (notification.status, true);
            status_widget.is_notification = true;
            status_widget.button_press_event.connect (status_widget.open);
            status_widget.avatar.button_press_event.connect (status_widget.open_account);
            attach (status_widget, 1, 3, 3, 1);
        }

        if (notification.type == NotificationType.FOLLOW_REQUEST) {
            var box = new Box (Orientation.HORIZONTAL, 6);
            box.margin_start = 32 + 16 + 8;
            var accept = new Button.with_label (_("Accept"));
            box.pack_start (accept, false, false, 0);
            var reject = new Button.with_label (_("Reject"));
            box.pack_start (reject, false, false, 0);

            attach (box, 1, 3, 3, 1);
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

    private void on_status_removed (int64 id) {
        if (id == notification.status.id) {
            if (notification.type == NotificationType.WATCHLIST)
                notification.dismiss ();

            destroy ();
        }
    }

}
