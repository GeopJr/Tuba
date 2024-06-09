public class Tuba.Views.Admin.Page.Base : Adw.NavigationPage {
	protected Gtk.Widget page { get; set; }
	private Gtk.ScrolledWindow scroller;
	private Gtk.Spinner spinner;
	private Adw.ToastOverlay toast_overlay;
	protected Adw.HeaderBar headerbar;
	protected Adw.ToolbarView toolbar_view;
	public weak Dialogs.Admin.Window? admin_window { get; set; }

	~Base () {
		debug (@"Destroying Admin Dialog page: $title");
	}

	private bool _spinning = true;
	protected bool spinning {
		get {
			return _spinning;
		}

		set {
			_spinning = value;
			if (value) {
				scroller.child = spinner;
			} else {
				scroller.child = page;
			}
		}
	}

	construct {
		headerbar = new Adw.HeaderBar ();
		spinner = new Gtk.Spinner () {
			valign = Gtk.Align.CENTER,
			hexpand = true,
			vexpand = true,
			spinning = true,
			height_request = 32
		};

		page = new Adw.PreferencesPage () {
			hexpand = true,
			vexpand = true,
			valign = Gtk.Align.CENTER
		};

		scroller = new Gtk.ScrolledWindow () {
			vexpand = true,
			hexpand = true,
			child = spinner
		};

		toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			hexpand = true,
			child = scroller
		};

		toolbar_view = new Adw.ToolbarView () {
			content = toast_overlay
		};
		toolbar_view.add_top_bar (headerbar);

		this.child = toolbar_view;
	}

	protected virtual void add_to_page (Adw.PreferencesGroup group) {
		var pref_page = page as Adw.PreferencesPage;
		if (pref_page != null)
			pref_page.add (group);
	}

	protected void add_toast (string content, uint timeout = 5) {
		toast_overlay.add_toast (new Adw.Toast (content) {
			timeout = timeout
		});
	}

	protected void on_error (int code, string message) {
		this.add_toast (@"$message $code");
	}
}
