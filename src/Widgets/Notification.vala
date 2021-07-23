using Gtk;

public class Tootle.Widgets.Notification : Widgets.Status {

    public API.Notification notification { get; construct set; }

    public Notification (API.Notification obj) {
        API.Status status;
        if (obj.status != null)
            status = obj.status;
        else
            status = new API.Status.from_account (obj.account);

        Object (
            notification: obj,
            kind_instigator: obj.account,
            kind: obj.kind,
            status: status
        );
    }

}
