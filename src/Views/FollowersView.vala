using Gtk;

public class Tootle.FollowersView : TimelineView {

    public FollowersView (Account account) {
        base (account.id.to_string ());
    }
    
    public new void append (Account account){
        if (empty != null)
            empty.destroy ();
    
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();

        var widget = new AccountWidget (account);
        widget.separator = separator;
        view.pack_start(separator, false, false, 0);
        view.pack_start(widget, false, false, 0);
    }
    
    public override string get_url (){
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/accounts/%s/followers".printf (accounts.formal.instance, this.timeline);
        return url;
    }
    
    public override void request (){
        var msg = new Soup.Message("GET", get_url ());
        msg.finished.connect (() => empty_state ());
        network.queue(msg, (sess, mess) => {
            try {
                network.parse_array (mess).foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null){
                        var status = Account.parse (object);
                        append (status);
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
