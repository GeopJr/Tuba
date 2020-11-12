using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/views/base.ui")]
public class Tootle.Views.Base : Box {

	public static string STATUS_EMPTY = _("Nothing to see here");
	public static string STATUS_LOADING = " ";

	public string? icon { get; set; default = null; }
	public string label { get; set; default = ""; }
	public bool needs_attention { get; set; default = false; }
	public bool current { get; set; default = false; }
	public SimpleActionGroup? actions { get; set; }

	public Container content { get; set; }

	[GtkChild]
	protected Hdy.HeaderBar header;
	[GtkChild]
	protected Button back_button;

	[GtkChild]
	protected ScrolledWindow scrolled;
	[GtkChild]
	protected Box view;
	[GtkChild]
	protected Hdy.Clamp clamp;
	[GtkChild]
	protected Box column_view;
	[GtkChild]
	protected Stack states;
	[GtkChild]
	protected Box content_box;
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

	public bool empty {
		get {
			return content.get_children ().length () <= 0;
		}
	}

	construct {
		bind_property ("label", header, "title", BindingFlags.SYNC_CREATE);

		content = content_list;

		status_button.label = _("Reload");
		bind_property ("state", states, "visible-child-name", BindingFlags.SYNC_CREATE);
		scrolled.edge_reached.connect (pos => {
			if (pos == PositionType.BOTTOM)
				on_bottom_reached ();
		});
		content.remove.connect (() => on_content_changed ());
		content_list.remove.connect (() => on_content_changed ());
		content_list.row_activated.connect (on_content_item_activated);

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

		scrolled.get_style_context ().add_class (Dialogs.MainWindow.ZOOM_CLASS);

		build_header ();
	}

	public virtual void build_header () {}

	public virtual void clear (){
		content.forall (w => {
			w.destroy ();
		});
		state = "status";
	}

	public virtual void on_bottom_reached () {}

	public virtual void on_shown () {
		if (actions != null)
			window.insert_action_group ("view", actions);
	}
	public virtual void on_hidden () {
		if (actions != null)
			window.insert_action_group ("view", null);
	}

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

	[GtkCallback]
	protected void on_resized () {
		Allocation alloc;
		get_allocation (out alloc);

		var target_w = clamp.maximum_size;
		var view_w = alloc.width;

		var ctx = view.get_style_context ();
		if (view_w <= target_w && ctx.has_class ("padded"))
			ctx.remove_class ("padded");
		if (view_w > target_w && !ctx.has_class ("padded"))
			ctx.add_class ("padded");
	}

	public virtual void on_content_item_activated (ListBoxRow row) {
		Signal.emit_by_name (row, "open");
	}

	[GtkCallback]
	void on_close () {
		window.back ();
	}

}
