[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/base.ui")]
public class Tuba.Views.Base : Adw.BreakpointBin {
	// translators: Fallback shown when there are 0 results
	public static string STATUS_EMPTY = _("Nothing to see here"); // vala-lint=naming-convention
	public string empty_state_title { get; set; default=STATUS_EMPTY; }

	public string? icon { get; set; default = null; }
	public string label { get; set; default = ""; }
	public bool needs_attention { get; set; default = false; }
	public bool is_main { get; set; default = false; }
	public bool allow_nesting { get; set; default = false; }
	public bool is_sidebar_item { get; set; default = false; }
	public int badge_number { get; set; default = 0; }
	public int uid { get; set; default = -1; }
	protected SimpleActionGroup actions { get; set; default = new SimpleActionGroup (); }
	public weak Gtk.Widget? last_widget { get; private set; default=null; }

	private bool _show_back_button = true;
	public bool show_back_button {
		get {
			return _show_back_button;
		}

		set {
			_show_back_button = value;
			update_back_btn ();
		}
	}

	private bool _current = false;
	public bool current {
		get {
			return _current;
		}

		set {
			_current = value;
			if (value) {
				on_shown ();
			} else {
				on_hidden ();
			}
		}
	}

	[GtkChild] protected unowned Adw.HeaderBar header;
	[GtkChild] protected unowned Adw.ToolbarView toolbar_view;

	[GtkChild] protected unowned Gtk.ScrolledWindow scrolled;
	[GtkChild] protected unowned Gtk.Overlay scrolled_overlay;
	[GtkChild] protected unowned Gtk.Revealer scroll_to_top_rev;
	[GtkChild] protected unowned Gtk.Button scroll_to_top;
	//  [GtkChild] protected unowned Gtk.Box view;
	//  [GtkChild] protected unowned Adw.Clamp clamp;
	//  [GtkChild] protected unowned Gtk.Box column_view;
	[GtkChild] protected unowned Gtk.Stack states;
	#if USE_LISTVIEW
		[GtkChild] protected unowned Adw.ClampScrollable content_box;
	#else
		[GtkChild] protected unowned Adw.Clamp content_box;
	#endif
	[GtkChild] protected unowned Gtk.Button status_button;
	[GtkChild] unowned Gtk.Image status_image;
	[GtkChild] unowned Gtk.Stack status_stack;
	[GtkChild] unowned Gtk.Label status_title_label;
	[GtkChild] unowned Gtk.Label status_message_label;
	[GtkChild] unowned Gtk.Spinner status_spinner;

	public class StatusMessage : Object {
		public string? title = null;
		public string? message = null;
		public bool loading = false;
	}

	private StatusMessage? _base_status = null;
	public StatusMessage? base_status {
		get {
			return _base_status;
		}
		set {
			status_image.visible = false;
			status_image.icon_name = "tuba-background-app-ghost-symbolic";
			status_button.visible = false;

			if (value == null) {
				states.visible_child_name = "content";
				status_spinner.spinning = false;
			} else {
				states.visible_child_name = "status";
				if (value.loading) {
					status_stack.visible_child_name = "spinner";
					status_spinner.spinning = true;
				} else {
					status_stack.visible_child_name = "message";
					status_spinner.spinning = false;

					if (value.title == null) {
						status_title_label.label = empty_state_title;
						status_image.visible = true;
					} else {
						status_title_label.label = value.title;
					}

					if (value.message != null)
						status_message_label.label = value.message;
				}
			}
			_base_status = value;
		}
	}

	construct {
		build_actions ();
		build_header ();

		status_button.label = _("Reload");
		base_status = new StatusMessage () { loading = true };

		// HACK to prevent memory leaks due to ref cycles.
		// Unfortunately, Vala seems to create ref cycles out of thin air,
		// especially when closures are involved, see e.g.
		// https://gitlab.gnome.org/GNOME/vala/-/issues/957
		// To work around that, we forcefully run dispose () -- which breaks any
		// ref cycles -- when we get removed from our parent widget, the
		// navigation view.
		notify["parent"].connect (() => {
			if (parent == null)
				dispose ();
		});

		scroll_to_top.clicked.connect (on_scroll_to_top);
		app.notify["is-mobile"].connect (update_back_btn);
	}
	~Base () {
		this.last_widget = null;
		debug (@"Destroying base $label");
	}

	private void update_back_btn () {
		header.show_back_button = app.is_mobile || show_back_button;

		// HACK - show_back_button doesn't seem to have any effect when
		// toggled on its own
		// https://gitlab.gnome.org/GNOME/libadwaita/-/issues/775
		header.show_start_title_buttons = !header.show_start_title_buttons;
		header.show_start_title_buttons = !header.show_start_title_buttons;
	}

	private void on_scroll_to_top () {
		scrolled.scroll_child (Gtk.ScrollType.START, false);
	}

	public virtual void scroll_page (bool up = false) {
		scrolled.scroll_child (up ? Gtk.ScrollType.PAGE_BACKWARD : Gtk.ScrollType.PAGE_FORWARD, false);
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
		this.last_widget = null;
		base_status = null;
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
		base_status = new StatusMessage () {
			title = _("An Error Occurred"),
			message = reason
		};

		status_image.icon_name = "tuba-sad-computer-symbolic";
		status_image.visible = true;
		status_button.visible = true;
		status_button.sensitive = true;
	}

	public void update_last_widget () {
		this.last_widget = app.main_window.get_focus ();
	}
}
