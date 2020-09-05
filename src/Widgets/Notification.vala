using Gtk;

public class Tootle.Widgets.Notification : Widgets.Status {

    public API.Notification notification { get; construct set; }

    public Notification (API.Notification obj) {
        API.Status status;
        if (obj.status != null)
            status = obj.status;
        else
            status = new API.Status.from_account (obj.account);

        Object (notification: obj, status: status);
        this.kind = obj.kind;
    }

    protected override void on_kind_changed () {
        if (kind == null)
            return;

        header_icon.visible = header_label.visible = true;
        header_icon.icon_name = kind.get_icon ();
        header_label.label = kind.get_desc (notification.account);
    }

}
