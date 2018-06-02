using Gtk;

public class Tootle.StatusView : AbstractView {

    private Status root_status;
    bool last_was_a_root = false;

    public StatusView (ref Status status) {
        base ();
        root_status = status;
        request_context ();
    }
    
    private void prepend (ref Status status, bool is_root = false){
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();
        
        var widget = new StatusWidget (ref status);
        widget.avatar.button_press_event.connect(widget.open_account);
        if (!is_root)
            widget.button_press_event.connect(widget.open);
        else
            widget.highlight ();
            
        if (!last_was_a_root) {
            widget.separator = separator;
            view.pack_start (separator, false, false, 0);
        }
        view.pack_start (widget, false, false, 0);
        last_was_a_root = is_root;
    }

    public Soup.Message request_context (){
        var url = "%s/api/v1/statuses/%lld/context".printf (Tootle.accounts.formal.instance, root_status.id);
        var msg = new Soup.Message("GET", url);
        network.queue (msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                
                var ancestors = root.get_array_member ("ancestors");
                ancestors.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = Status.parse (object);
                        prepend (ref status);
                    }
                });
                
                prepend (ref root_status, true);
                
                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = Status.parse (object);
                        prepend (ref status);
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
        var msg = new Soup.Message("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        network.queue (msg, (sess, mess) => {
            try{
                var root = network.parse (mess);
                var statuses = root.get_array_member ("statuses");
                var object = statuses.get_element (0).get_object ();
                if (object != null){
                    var st = Status.parse (object);
                    window.open_view (new StatusView (ref st));
                }
                else
                    app.toast (_("Toot not found"));
            }
            catch (GLib.Error e) {
                warning (e.message);
            }
        });
    }

}
