using Gtk;

public class Tootle.Views.ExpandedStatus : Views.Abstract {

    private API.Status root_status;
    private bool last_status_was_root = false;
    private bool sensitive_visible = false;

    public ExpandedStatus (API.Status status) {
        base ();
        root_status = status;
        request ();

        window.button_reveal.clicked.connect (on_reveal_toggle);
    }

    ~ExpandedStatus () {
        if (window != null) {
            window.button_reveal.clicked.disconnect (on_reveal_toggle);
            window.button_reveal.hide ();
        }
    }

    private void prepend (API.Status status, bool is_root = false){
        var separator = new Separator (Orientation.HORIZONTAL);
        separator.show ();

        var widget = new Widgets.Status (status);
        widget.avatar.button_press_event.connect (widget.on_avatar_clicked);
        if (!is_root)
            widget.button_press_event.connect (widget.open);
        else
            widget.highlight ();

        if (!last_status_was_root) {
            widget.separator = separator;
            view.pack_start (separator, false, false, 0);
        }
        view.pack_start (widget, false, false, 0);
        last_status_was_root = is_root;

        if (status.has_spoiler ())
            window.button_reveal.show ();
        if (sensitive_visible)
            reveal_sensitive (widget);
    }

    public Soup.Message request (){
        var url = "%s/api/v1/statuses/%lld/context".printf (accounts.formal.instance, root_status.id);
        var msg = new Soup.Message ("GET", url);
        network.queue (msg, (sess, mess) => {
            try{
                var root = network.parse (mess);

                var ancestors = root.get_array_member ("ancestors");
                ancestors.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = API.Status.parse (object);
                        prepend (status);
                    }
                });

                prepend (root_status, true);

                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = API.Status.parse (object);
                        prepend (status);
                    }
                });
            }
            catch (GLib.Error e) {
                warning ("Can't get context for a status");
                warning (e.message);
            }
        });
        return msg;
    }

    public static void open_from_link (string q){
        var url = "%s/api/v1/search?q=%s&resolve=true".printf (accounts.formal.instance, q);
        var msg = new Soup.Message ("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        network.queue (msg, (sess, mess) => {
            try {
                var root = network.parse (mess);
                var statuses = root.get_array_member ("statuses");
                var object = statuses.get_element (0).get_object ();
                if (object != null){
                    var st = API.Status.parse (object);
                    window.open_view (new Views.ExpandedStatus (st));
                }
                else
                    Desktop.open_uri (q);
            }
            catch (GLib.Error e) {
                warning (e.message);
            }
        });
    }

    private void on_reveal_toggle () {
        sensitive_visible = !sensitive_visible;
        view.forall (w => {
            if (!(w is Widgets.Status))
                return;

            var widget = w as Widgets.Status;
            reveal_sensitive (widget);
        });
    }

    private void reveal_sensitive (Widgets.Status widget) {
        if (widget.status.has_spoiler ())
            widget.revealer.reveal_child = sensitive_visible;
    }

}
