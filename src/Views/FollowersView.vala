using Gtk;

public class Tootle.FollowersView : TimelineView {

    public FollowersView (ref Account account) {
        base (account.id.to_string ());
        
    }
    
    public new void prepend (ref Account account){
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();

        var widget = new AccountWidget (ref account);
        widget.separator = separator;
        view.pack_start(separator, false, false, 0);
        view.pack_start(widget, false, false, 0);
    }
    
    public override string get_url (){
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/accounts/%s/followers".printf (Tootle.settings.instance_url, this.timeline);
        return url;
    }
    
    public override void request (){
        var msg = new Soup.Message("GET", get_url ());
        debug (get_url ());
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                Tootle.network.parse_array (mess).foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null){
                        var status = Account.parse (object);
                        prepend (ref status);
                    }
                });
                
                get_pages (mess.response_headers.get_one ("Link"));
            }
            catch (GLib.Error e) {
                warning ("Can't get account follow info:");
                warning (e.message);
            }
        });
    }

}
