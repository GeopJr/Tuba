using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/base.ui")]
public class Tootle.Views.Base : Box {

    public static string STATUS_EMPTY = _("Nothing to see here");
    public static string STATUS_LOADING = " ";

    public bool current = false;
    public int stack_pos = -1;
    public Image? image;

    [GtkChild]
    protected ScrolledWindow scrolled;
    [GtkChild]
    protected Box view;
    [GtkChild]
    protected Stack states;
    [GtkChild]
    protected Box content;
    [GtkChild]
    private Label status_message_label;
    [GtkChild]
    protected Button status_button;
    [GtkChild]
    private Stack status_stack;

    public string state { get; set; default = "status"; }
    public string status_message { get; set; default = STATUS_EMPTY; }
    public bool allow_closing { get; set; default = true; }

    public bool empty {
        get {
            return content.get_children ().length () <= 0;
        }
    }

    construct {
        status_button.label = _("Reload");
        bind_property ("state", states, "visible-child-name", BindingFlags.SYNC_CREATE);
        scrolled.edge_reached.connect (pos => {
            if (pos == PositionType.BOTTOM)
                on_bottom_reached ();
        });
        content.remove.connect (() => on_content_changed ());

        notify["status-message"].connect (() => {
            status_message_label.label = @"<span size='large'>$status_message</span>";
            status_stack.visible_child_name = status_message == STATUS_LOADING ? "spinner" : "message";
        });
    }

    public virtual string get_icon () {
        return "null";
    }

    public virtual string get_name () {
        return "unnamed";
    }

    public virtual void clear (){
        content.forall (widget => {
            widget.destroy ();
        });
        state = "status";
    }

    public virtual void on_bottom_reached () {}
    public virtual void on_set_current () {}

    public virtual void on_content_changed () {
        if (empty) {
            status_message = STATUS_EMPTY;
            state = "status";
        }
        else {
            state = "content";
        }
        check_resize ();
    }

    public virtual void on_error (int32 code, string reason) {
        status_message = reason;
        status_button.visible = true;
        status_button.sensitive = true;
        state = "status";
    }

}
