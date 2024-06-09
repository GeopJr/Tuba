public class Tuba.Views.Admin.Page.Reports : Views.Admin.Page.Base {
	Views.Admin.Timeline.Reports pagination_timeline;
	Gtk.ToggleButton resolved_button;
	construct {
		// translators: Admin Dialog page title
		this.title = _("Reports");

		resolved_button = new Gtk.ToggleButton () {
			// translators: admin dashboard, reports timeline, headerbar button tooltip text
			tooltip_text = _("Show Resolved Reports"),
			css_classes = {"flat"},
			icon_name = "tuba-check-round-outline-symbolic"
		};
		resolved_button.toggled.connect (on_resolved_toggled);
		headerbar.pack_end (resolved_button);

		pagination_timeline = new Views.Admin.Timeline.Reports ();
		pagination_timeline.on_open_report_dialog.connect (open_report_dialog);
		pagination_timeline.on_error.connect (on_error);
		pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
		pagination_timeline.bind_property ("working", resolved_button, "sensitive", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		this.page = pagination_timeline;

		refresh ();
	}

	private void on_resolved_toggled () {
		pagination_timeline.reset (resolved_button.active ? "/api/v1/admin/reports?resolved=true" : "/api/v1/admin/reports");
	}

	private void refresh () {
		pagination_timeline.request_idle ();
	}

	private void open_report_dialog (API.Admin.Report report) {
		var report_dialog = new Dialogs.Admin.Report (report);
		report_dialog.refresh.connect (refresh);
		report_dialog.present (this.admin_window);
	}
}
