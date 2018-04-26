using Gtk;
using Gdk;

public class Tootle.HomeView : Tootle.AbstractView {
    
    private string timeline;

    public HomeView (string timeline = "home") {
        base (true);
        this.timeline = timeline;
        
        view.remove.connect (on_remove);
        AccountManager.instance.switched.connect(on_account_changed);
        
        // var s = new Status(1);
        // s.content = "Test content, wow!";
        // prepend (s);
    }
    
    public override string get_icon () {
        return "user-home-symbolic";
    }
    
    public override string get_name () {
        return "Home";
    }
    
    public virtual bool is_status_owned (Status status){
        return false;
    }
    
    public void prepend(Status status){
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();
        
        var widget = new StatusWidget(status);
        widget.separator = separator;
        widget.rebind (status);
        widget.button_press_event.connect(widget.open);
        if (!is_status_owned (status))
            widget.avatar.button_press_event.connect(widget.on_avatar_clicked);
        view.pack_start(separator, false, false, 0);
        view.pack_start(widget, false, false, 0);
    }
    
    public virtual void on_remove (Widget widget){
        if (!(widget is StatusWidget))
            return;
            
        //TODO: empty state
    }
    
    public virtual string get_url (){
        var url = Settings.instance.instance_url;
        url += "api/v1/timelines/";
        url += this.timeline;
        url += "?limit=25";
        
        if (max_id > 0)
            url += "&max_id=" + max_id.to_string ();
        
        return url;
    }
    
    public void request (){
        var msg = new Soup.Message("GET", get_url ());
        NetManager.instance.queue(msg, (sess, mess) => {
            try{
                NetManager.parse_array (mess).foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null){
                        var status = Status.parse(object);
                        max_id = status.id;
                        prepend (status);
                    }
                });
            }
            catch (GLib.Error e) {
                warning ("Can't update feed");
                warning (e.message);
            }
        });
    }
    
    public virtual void on_account_changed (Account? account){
        if(account == null)
            return;
        
        clear ();
        request ();
    }
    
    public override void bottom_reached (){
        request ();
    }

}
