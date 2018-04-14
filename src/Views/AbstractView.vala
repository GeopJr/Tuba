using Gtk;

public abstract class Tootle.AbstractView : Gtk.Box {
    
    public bool show_in_header;

    public AbstractView (bool show_in_header) {
        this.show_in_header = show_in_header;
    }
    
    public virtual string get_icon () {
        return "null";
    }
    
    public virtual string get_name () {
        return "unnamed";
    }

}
