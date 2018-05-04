using Gtk;

public class Tootle.StatusView : Tootle.AbstractView {

    Status root_status;
    bool last_was_a_root = false;

    public StatusView (Status status) {
        base (false);
        root_status = status;
        request_context ();
    }
    
    private void prepend (Status status, bool is_root = false){
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();
        var widget = new StatusWidget(status);
        if (is_root)
            widget.highlight ();
        
        widget.content_label.selectable = true;
        if (widget.content_spoiler != null)
            widget.content_spoiler.selectable = true;
        widget.avatar.button_press_event.connect(widget.on_avatar_clicked);
        if (!last_was_a_root) {
            widget.separator = separator;
            view.pack_start (separator, false, false, 0);
        }
        view.pack_start (widget, false, false, 0);
        last_was_a_root = is_root;
    }

    public Soup.Message request_context (){
        var url = "%s/api/v1/statuses/%lld/context".printf (Tootle.settings.instance_url, root_status.id);
        var msg = new Soup.Message("GET", url);
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                
                var ancestors = root.get_array_member ("ancestors");
                ancestors.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null)
                        prepend (Status.parse(object));
                });
                
                prepend (root_status, true);
                
                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null)
                        prepend (Status.parse(object));
                });
            }
            catch (GLib.Error e) {
                warning ("Can't get context for a status");
                warning (e.message);
            }
        });
        return msg;
    }

}


