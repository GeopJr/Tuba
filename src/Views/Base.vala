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
	public Gtk.Widget? last_widget { get; private set; default=null; }
	public string empty_timeline_icon { get; set; default="tuba-background-app-ghost-symbolic"; }

	bool _small = false;
	public bool small {
		get { return _small; }
		set {
			_small = value;
			if (!value && !content_box.has_css_class ("large-view")) {
				content_box.add_css_class ("large-view");
			} else if (value && content_box.has_css_class ("large-view")) {
				content_box.remove_css_class ("large-view");
			}
		}
	}

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
			status_image.icon_name = this.empty_timeline_icon;
			status_button.visible = false;
			this.update_state (Gtk.AccessibleState.BUSY, false, -1);
			this.update_property (Gtk.AccessibleProperty.LABEL, null, -1);

			if (value == null) {
				if (states.visible_child_name != "content") states.visible_child_name = "content";
			} else {
				if (states.visible_child_name != "status") states.visible_child_name = "status";
				if (value.loading) {
					if (status_stack.visible_child_name != "spinner") status_stack.visible_child_name = "spinner";
					this.update_state (Gtk.AccessibleState.BUSY, true, -1);
				} else {
					if (status_stack.visible_child_name != "message") status_stack.visible_child_name = "message";

					if (value.title == null) {
						status_title_label.label = empty_state_title;
						status_image.visible = true;
					} else {
						status_title_label.label = value.title;
					}

					if (value.message != null)
						status_message_label.label = value.message;

					this.update_property (
						Gtk.AccessibleProperty.LABEL,
						@"$(status_title_label.label) $(status_message_label.label)",
						-1
					);
				}
			}
			_base_status = value;
		}
	}

	construct {
		var breakpoint = new Adw.Breakpoint (new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			670, Adw.LengthUnit.PX
		));
		breakpoint.add_setter (this, "small", true);
		add_breakpoint (breakpoint);

		build_actions ();
		build_header ();

		status_button.label = _("Reload");
		base_status = new StatusMessage () { loading = true };

		// HACK to prevent memory leaks due to ref cycles.
		// Unfortunately, Vala seems to create ref cycles out of thin air,
		// especially when closures are involved, see e.g.
		// https://gitlab.gnome.org/GNOME/vala/-/issues/957
		// or model binding.
		// To work around that, we clear the binding manually.
		#if !USE_LISTVIEW
			notify["parent"].connect (() => {
				if (parent == null)
					unbind_listboxes ();
			});
		#endif

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

	#if !USE_LISTVIEW
		public virtual void unbind_listboxes () {
			this.last_widget = null;
		}
	#endif

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

	public void update_last_widget (bool clear = false) {
		this.last_widget = clear ? null : app.main_window.get_focus ();
		// Alternative way to grab focus of label links
		// Currently replaced by RichLabel's activate_link's
		// grab_focus as it's more reliable for this use case
		//
		//  if ((this.last_widget as Gtk.Label) != null) {
		//  	this.last_widget = this.last_widget.get_focus_child ();
		//  }
	}
}
