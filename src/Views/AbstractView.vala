using Gtk;

public abstract class Tootle.AbstractView : Gtk.ScrolledWindow {

    public Gtk.Image? image;
    public Gtk.Box view;
    protected Gtk.Box? empty;

    construct {
        view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        view.valign = Gtk.Align.START;
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        add (view);
        
        edge_reached.connect(pos => {
            if (pos == Gtk.PositionType.BOTTOM)
                bottom_reached ();
        });
        
        pre_construct ();
    }

    public AbstractView () {
        show_all ();
    }
    
    public virtual string get_icon () {
        return "null";
    }
    
    public virtual string get_name () {
        return "unnamed";
    }
    
    public virtual void clear (){
        view.forall (widget => widget.destroy ());
        pre_construct ();
    }
    
    public virtual void pre_construct () {}
    
    public virtual void bottom_reached (){}
    
    public virtual bool is_empty () {
        return view.get_children ().length () <= 1;
    }
    
    public virtual bool empty_state () {
        if (empty != null)
            empty.destroy ();
        if (!is_empty ())
            return false;
        
        empty = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        empty.margin = 64;
        var image = new Image.from_resource ("/com/github/bleakgrey/tootle/empty_state");
        var text = new Gtk.Label (_("Nothing to see here"));
        text.get_style_context ().add_class ("h2");
        text.opacity = 0.5;
        empty.vexpand = true;
        empty.valign = Gtk.Align.FILL;
        empty.pack_start (image, false, false, 0);
        empty.pack_start (text, false, false, 12);
        empty.show_all ();
        view.pack_start (empty, false, false, 0);
        
        return true;
    }
    
}
