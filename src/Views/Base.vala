using Gtk;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/base.ui")]
public class Tuba.Views.Base : Box {

	public static string STATUS_EMPTY = _("Nothing to see here");

	public string? icon { get; set; default = null; }
	public string label { get; set; default = ""; }
	public bool needs_attention { get; set; default = false; }
	public bool current { get; set; default = false; }
	public bool is_main { get; set; default = false; }
	public bool is_profile { get; set; default = false; }
	public bool is_sidebar_item { get; set; default = false; }
	public int badge_number { get; set; default = 0; }
	protected SimpleActionGroup actions { get; set; default = new SimpleActionGroup (); }

	[GtkChild] protected unowned Adw.HeaderBar header;
	[GtkChild] protected unowned Button back_button;

	[GtkChild] protected unowned ScrolledWindow scrolled;
	[GtkChild] protected unowned Overlay scrolled_overlay;
	[GtkChild] protected unowned Button scroll_to_top;
	[GtkChild] protected unowned Box view;
	[GtkChild] protected unowned Adw.Clamp clamp;
	[GtkChild] protected unowned Box column_view;
	[GtkChild] protected unowned Stack states;
	[GtkChild] protected unowned Box content_box;
	[GtkChild] protected unowned Button status_button;
	[GtkChild] unowned Stack status_stack;
	[GtkChild] unowned Label status_title_label;
	[GtkChild] unowned Label status_message_label;
	[GtkChild] unowned Spinner status_spinner;

	public string state { get; set; default = "status"; }
	public string status_title { get; set; default = STATUS_EMPTY; }
	public string status_message { get; set; default = STATUS_EMPTY; }
	public bool status_loading { get; set; default = false; }

	construct {
	    build_actions ();
	    build_header ();

		status_button.label = _("Reload");
		bind_property ("state", states, "visible-child-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (src.get_string ());
			if (src.get_string () != "status") status_spinner.spinning = false;

			return true;
		});
		bind_property ("status-loading", status_stack, "visible-child-name", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (src.get_boolean ()  ? "spinner" : "message");
			status_spinner.spinning = src.get_boolean ();

			return true;
		});
		bind_property ("status-message", status_message_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var src_s = src.get_string ();
			target.set_string (src_s);
			status_message_label.visible = src_s != STATUS_EMPTY && src_s != "";
			return true;
		});
		bind_property ("status-title", status_title_label, "label", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var src_s = src.get_string ();
			target.set_string (src_s);
			status_message = STATUS_EMPTY;
			status_loading = src_s == "";
			return true;
		});

		notify["status-title"].connect (() => {
			status_title_label.label = status_title;
			status_message = STATUS_EMPTY;
		});

		notify["current"].connect (() => {
			if (current)
				on_shown ();
			else
				on_hidden ();
		});

		scrolled.get_style_context ().add_class (Dialogs.MainWindow.ZOOM_CLASS);

		scroll_to_top.clicked.connect(on_scroll_to_top);
	}
	~Base () {
		message ("Destroying base "+label);
	}

	private void on_scroll_to_top () {
		scrolled.vadjustment.value = 0.0;
	}

	public override void dispose () {
		actions.dispose ();
		base.dispose ();
	}

    protected virtual void build_actions () {}

	protected virtual void build_header () {
		var title = new Adw.WindowTitle (label, "");
		bind_property ("label", title, "title", BindingFlags.SYNC_CREATE);
		header.title_widget = title;
	}

	public virtual void clear () {
		state = "status";
	}

	public virtual void on_shown () {
		if (app != null && app.main_window != null)
			app.main_window.insert_action_group ("view", actions);
	}
	public virtual void on_hidden () {
		if (app != null && app.main_window != null)
			app.main_window.insert_action_group ("view", null);
	}

	public virtual void on_content_changed () {}

	public virtual void on_error (int32 code, string reason) {
		status_title = _("An Error Occurred");
		status_message = reason;
		status_button.visible = true;
		status_button.sensitive = true;
		state = "status";
	}

	[GtkCallback]
	void on_close () {
		app.main_window.back ();
	}

}
