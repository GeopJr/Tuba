public class Tuba.Views.Admin.Timeline.Reports : Views.Admin.Timeline.PaginationTimeline {
	~Reports () {
		debug ("Destroying Reports");
	}

	construct {
		this.url = "/api/v1/admin/reports";
		this.accepts = typeof (API.Admin.Report);
	}

	public signal void on_open_report_dialog (API.Admin.Report report);
	public override Gtk.Widget on_create_model_widget (Object obj) {
		Gtk.Widget widget = base.on_create_model_widget (obj);
		var action_row = widget as Widgets.Admin.Report;
		if (action_row != null) {
			action_row.report_activated.connect (on_report_activated);
		}

		return widget;
	}

	private void on_report_activated (API.Admin.Report report) {
		on_open_report_dialog (report);
	}
}
