using Gtk;

public class Tootle.StatusView : Tootle.AbstractView {

    Status root_status;

    public StatusView (Status status) {
        base (false);
        root_status = status;
        request_context ();
    }
    
    private void prepend (Status status, bool is_root = false){
        var widget = new StatusWidget(status);
        
        if (is_root)
            widget.highlight ();
        else
            widget.margin_start = 24;
        
        widget.rebind (status);
        widget.content.selectable = true;
        if (widget.spoiler_content != null)
            widget.spoiler_content.selectable = true;
        view.pack_start (widget, false, false, 0);
    }

    public Soup.Message request_context (){
        var url = "%s/api/v1/statuses/%lld/context".printf (Settings.instance.instance_url, root_status.id);
        var msg = new Soup.Message("GET", url);
        NetManager.instance.queue(msg, (sess, mess) => {
            try{
                var root = NetManager.parse (mess);
                
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


