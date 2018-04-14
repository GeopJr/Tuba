using Gtk;
using Gdk;

public class Tootle.HomeView : Tootle.AbstractView {

    Gtk.Box view;
    Gtk.ScrolledWindow scroll;
    
    private string timeline;
    private string pars;

    construct {
        view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        view.hexpand = true;
        view.valign = Gtk.Align.START;

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hexpand = true;
        scroll.vexpand = true;
        scroll.hscrollbar_policy = Gtk.PolicyType.NEVER;
        scroll.add (view);
        add (scroll);
    }

    public HomeView (string timeline = "home", string pars = "") {
        base (true);
        this.timeline = timeline;
        this.pars = pars;
        
        show_all();
        
        AccountManager.instance.changed_current.connect(on_account_changed);
        
        // var s = new Status(1);
        // s.content = "Test content, wow!";
        // prepend (s);
    }
    
    public override string get_icon () {
        return "user-home-symbolic";
    }
    
    public override string get_name () {
        return "Home Timeline";
    }
    
    public void prepend(Status status){
        var widget = new StatusWidget();
        widget.rebind (status);
        view.pack_end (widget, false, false, 0);
    }
    
    public virtual void on_account_changed (Account? account){
        if(account == null)
            return;
        
        var url = Settings.instance.instance_url;
        url += "api/v1/timelines/";
        url += this.timeline;
        url += this.pars;
        
        var msg = new Soup.Message("GET", url);
        NetManager.instance.queue(msg, (sess, mess) => {
            try{
                NetManager.parse_array (mess).foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null){
                        var status = Status.parse(object);
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

}
