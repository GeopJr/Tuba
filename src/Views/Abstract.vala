using Gtk;

public abstract class Tootle.Views.Abstract : ScrolledWindow {

    public bool current = false;
    public int stack_pos = -1;
    public Image? image;
    public Box view;
    protected Box? empty;
    protected Grid? header;

    construct {
        view = new Box (Orientation.VERTICAL, 0);
        view.valign = Align.START;
        add (view);

        hscrollbar_policy = PolicyType.NEVER;
        edge_reached.connect (pos => {
            if (pos == PositionType.BOTTOM)
                on_bottom_reached ();
        });
    }

    public Abstract () {
        show_all ();
    }

    public virtual string get_icon () {
        return "null";
    }

    public virtual string get_name () {
        return "unnamed";
    }

    public virtual void clear (){
        view.forall (widget => {
            if (widget != header)
                widget.destroy ();
        });
    }

    public virtual void on_bottom_reached () {}
    public virtual void on_set_current () {}

    public virtual bool is_empty () {
        return view.get_children ().length () <= 1;
    }

    public virtual bool empty_state () {
        if (empty != null)
            empty.destroy ();
        if (!is_empty ())
            return false;

        empty = new Box (Orientation.VERTICAL, 0);
        empty.margin = 64;
        var image = new Image.from_resource ("/com/github/bleakgrey/tootle/empty_state");
        var text = new Label (_("Nothing to see here"));
        text.get_style_context ().add_class ("h2");
        text.opacity = 0.5;
        empty.hexpand = true;
        empty.vexpand = true;
        empty.valign = Align.FILL;
        empty.pack_start (image, false, false, 0);
        empty.pack_start (text, false, false, 12);
        empty.show_all ();
        view.pack_start (empty, false, false, 0);

        return true;
    }

}
