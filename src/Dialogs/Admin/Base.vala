public class Tuba.Dialogs.Admin.Base : Adw.Dialog {
	~Base () {
		debug ("Destroying Dialog Admin Base");
	}

	Adw.ToastOverlay toast_overlay;
	protected Adw.PreferencesPage page { get; set; }
	protected Adw.HeaderBar headerbar { get; set; }
	construct {
		page = new Adw.PreferencesPage ();
		toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			hexpand = true,
			child = page
		};
		var toolbarview = new Adw.ToolbarView () {
			content = toast_overlay,
			valign = Gtk.Align.CENTER
		};
		headerbar = new Adw.HeaderBar ();
		toolbarview.add_top_bar (headerbar);
		this.child = toolbarview;
	}

	protected void add_toast (string content) {
		toast_overlay.add_toast (new Adw.Toast (content) {
			timeout = 5
		});
	}
}
