using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/base.ui")]
public class Tootle.Views.Base : Box {

    public static string STATUS_EMPTY = _("Nothing to see here");
    public static string STATUS_LOADING = " ";

    public int stack_pos { get; set; default = -1; }
	public string? icon { get; set; default = null; }
	public string label { get; set; default = ""; }
	public bool needs_attention { get; set; default = false; }
	public bool current { get; set; default = false; }

    [GtkChild]
    protected ScrolledWindow scrolled;
    [GtkChild]
    protected Box view;
    [GtkChild]
    protected Hdy.Column column;
    [GtkChild]
    protected Box column_view;
    [GtkChild]
    protected Stack states;
    [GtkChild]
    protected Box content;
    [GtkChild]
    protected ListBox content_list;
    [GtkChild]
    protected Button status_button;
    [GtkChild]
    Stack status_stack;
    [GtkChild]
    Label status_message_label;

    public string state { get; set; default = "status"; }
    public string status_message { get; set; default = STATUS_EMPTY; }
    public bool allow_closing { get; set; default = true; }

    public bool empty {
        get {
            return content_list.get_children ().length () <= 0;
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
        content_list.remove.connect (() => on_content_changed ());

        notify["status-message"].connect (() => {
            status_message_label.label = @"<span size='large'>$status_message</span>";
            status_stack.visible_child_name = status_message == STATUS_LOADING ? "spinner" : "message";
        });

        notify["current"].connect (() => {
            if (current)
                on_shown ();
            else
                on_hidden ();
        });

        size_allocate.connect (on_resized);
        get_style_context ().add_class (Dialogs.MainWindow.ZOOM_CLASS);
    }

    public virtual void clear (){
        content_list.forall (widget => {
            widget.destroy ();
        });
        state = "status";
    }

    public virtual void on_bottom_reached () {}
    public virtual void on_shown () {}
    public virtual void on_hidden () {}

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

    protected void on_resized () {
        Allocation alloc;
        get_allocation (out alloc);

        var target_w = column.maximum_width;
        var view_w = alloc.width;

        var ctx = view.get_style_context ();
        if (view_w <= target_w && ctx.has_class ("padded"))
            ctx.remove_class ("padded");
        if (view_w > target_w && !ctx.has_class ("padded"))
            ctx.add_class ("padded");
    }

}
