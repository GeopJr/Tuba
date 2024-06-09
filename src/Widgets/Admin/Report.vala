public class Tuba.Widgets.Admin.Report : Adw.ActionRow {
	public signal void report_activated (API.Admin.Report report);

	~Report () {
		debug ("Destroying Report");
	}

	API.Admin.Report report;
	public Report (API.Admin.Report report) {
		this.report = report;
		this.activated.connect (on_activate);
		this.activatable = true;
		this.overflow = Gtk.Overflow.HIDDEN;
		this.subtitle_lines = 0;
		this.title = report.target_account.account.full_handle;

		string last_line_title;
		string last_line_subtitle;
		if (report.action_taken) {
			last_line_subtitle = report.action_taken_by_account == null ? _("Nobody") : report.action_taken_by_account.account.full_handle;
			// translators: Report 'Action Taken by: <account>'
			last_line_title = _("Action Taken by");
		} else {
			last_line_subtitle = report.assigned_account == null ? _("Nobody") : report.assigned_account.account.full_handle;
			// translators: Report 'Assigned to: <account>'
			last_line_title = _("Assigned to");
		}

		this.subtitle = "<b>%s:</b> %s\n<b>%s:</b> %d\n<b>%s:</b> %s".printf (
			// translators: 'Reported by: <account>'
			_("Reported by"),
			report.account.account.full_handle,
			// translators: 'Reported Posts: <amount>'
			_("Reported Posts"),
			report.statuses == null ? 0 : report.statuses.size,
			last_line_title,
			last_line_subtitle
		);

		this.add_prefix (new Widgets.Avatar () {
			account = report.target_account.account,
			size = 48,
			overflow = Gtk.Overflow.HIDDEN
		});

		// translators: Admin dashboard, report status
		string status = _("No Limits");
		if (report.action_taken) {
			if (report.target_account.suspended) {
				status = _("Suspended");
			} else if (report.target_account.silenced) {
				status = _("Limited");
			} else if (report.target_account.disabled) {
				status = _("Disabled");
			}
		}

		this.add_suffix (new Gtk.Label (status) {
			xalign = 1.0f,
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			hexpand = true
		});
	}

	private void on_activate () {
		report_activated (report);
	}
}
