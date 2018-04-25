using Gtk;

public abstract class Tootle.AbstractView : Gtk.ScrolledWindow {
    
    public bool show_in_header;
    public Gtk.Image image;
    public Gtk.Box view;

    construct {
        view = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        hscrollbar_policy = Gtk.PolicyType.NEVER;
        add (view);
    }

    public AbstractView (bool show) {
        show_in_header = show;
        show_all ();
    }
    
    public virtual string get_icon () {
        return "null";
    }
    
    public virtual string get_name () {
        return "unnamed";
    }
    
}
