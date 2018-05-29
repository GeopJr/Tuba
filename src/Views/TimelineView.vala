using Gtk;
using Gdk;

public class Tootle.TimelineView : AbstractView {
    
    protected string timeline;
    protected string pars;
    
    protected int limit = 25;
    protected bool is_last_page = false;
    protected string? page_next;
    protected string? page_prev;

    public TimelineView (string timeline, string pars = "") {
        base ();
        this.timeline = timeline;
        this.pars = pars;
        
        Tootle.accounts.switched.connect(on_account_changed);
        Tootle.app.refresh.connect(on_refresh);
        Tootle.network.status_added.connect (on_status_added);
        
        request ();
    }
    
    public override string get_icon () {
        return "user-home-symbolic";
    }
    
    public override string get_name () {
        return _("Home");
    }
    
    private void on_status_added (ref Status status, string timeline) {
        if (timeline != this.timeline)
            return;
        
        prepend (ref status);
    }
    
    public virtual bool is_status_owned (ref Status status) {
        return status.is_owned ();
    }
    
    public void prepend (ref Status status) {
        append (ref status, true);
    }
    
    public void append (ref Status status, bool first = false){
        if (empty != null)
            empty.destroy ();
    
        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);
        separator.show ();

        var widget = new StatusWidget (ref status);
        widget.separator = separator;
        widget.button_press_event.connect(widget.open);
        if (!is_status_owned (ref status))
            widget.avatar.button_press_event.connect(widget.open_account);
        view.pack_start(separator, false, false, 0);
        view.pack_start(widget, false, false, 0);
        
        if (first) {
            view.reorder_child (widget, 0);
            view.reorder_child (separator, 0);
        }
    }
    
    public override void clear () {
        this.page_prev = null;
        this.page_next = null;
        this.is_last_page = false;
        base.clear ();
    }
    
    public void get_pages (string? header) {
        page_next = page_prev = null;
        if (header == null)
            return;
        
        var pages = header.split (",");
        foreach (var page in pages) {
            var sanitized = page
                .replace ("<","")
                .replace (">", "")
                .split (";")[0];

            if ("rel=\"prev\"" in page)
                page_prev = sanitized;
            else
                page_next = sanitized;
        }
        
        is_last_page = page_prev != null & page_next == null;
    }
    
    public virtual string get_url () {
        if (page_next != null)
            return page_next;
        
        var url = "%s/api/v1/timelines/%s?limit=%i".printf (Tootle.accounts.formal.instance, this.timeline, this.limit);
        url += this.pars;
        return url;
    }
    
    public virtual void request (){
        if (accounts.current == null) {
            empty_state ();
            return;
        }
        
        var msg = new Soup.Message("GET", get_url ());
        msg.finished.connect (() => empty_state ());
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                Tootle.network.parse_array (mess).foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null){
                        var status = Status.parse(object);
                        append (ref status);
                    }
                });
                get_pages (mess.response_headers.get_one ("Link"));
            }
            catch (GLib.Error e) {
                warning ("Can't update feed");
                warning (e.message);
            }
        });
    }
    
    public virtual void on_refresh (){
        clear ();
        request ();
    }
    
    public virtual void on_account_changed (Account? account){
        if(account == null)
            return;
        on_refresh ();
    }
    
    public override void bottom_reached (){
        if (is_last_page) {
            debug ("Last page reached");
            return;
        }
        request ();
    }

}
