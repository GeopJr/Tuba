public class Tuba.Widgets.Admin.AssignedToRow : Adw.ActionRow {
	public signal void assignment_changed (string new_handle);
	public signal void on_error (string error_message);

	~AssignedToRow () {
		debug ("Destroying AssignedToRow");
	}

	Gtk.Button assign_button;
	construct {
		this.title = _("Assigned to");
		this.subtitle_selectable = true;

		assign_button = new Gtk.Button () {
			valign = Gtk.Align.CENTER
		};
		assign_button.clicked.connect (do_assign);
		this.add_suffix (assign_button);
	}

	string report_id;
	public AssignedToRow (string report_id, API.Admin.Account? assigned_account) {
		this.report_id = report_id;
		update_account (assigned_account);
	}

	bool _is_assigned = false;
	bool is_assigned {
		get {
			return _is_assigned;
		}

		set {
			_is_assigned = value;
			if (value) {
				assign_button.add_css_class ("destructive-action");
				assign_button.remove_css_class ("suggested-action");
				assign_button.label = _("Unassign");
			} else {
				assign_button.add_css_class ("suggested-action");
				assign_button.remove_css_class ("destructive-action");
				assign_button.label = _("Assign");
			}
		}
	}

	private void update_account (API.Admin.Account? assigned_account) {
		if (assigned_account == null) {
			this.subtitle = _("Nobody");
			assign_button.visible = true;
			is_assigned = false;
		} else {
			assign_button.visible = assigned_account.account.id == accounts.active.id;
			this.subtitle = assigned_account.account.full_handle;
			is_assigned = true;
		}

		assignment_changed (this.subtitle);
	}

	private void do_assign () {
		string endpoint = is_assigned ? "unassign" : "assign_to_self";
		assign_button.sensitive = false;
		new Request.POST (@"/api/v1/admin/reports/$report_id/$endpoint")
			.with_account (accounts.active)
			.then ((in_stream) => {
				Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
					try {
						var parser = Network.get_parser_from_inputstream_async.end (res);
						var node = network.parse_node (parser);
						update_account (API.Admin.Report.from (node).assigned_account);
					} catch (Error e) {
						critical (@"Couldn't parse json: $(e.code) $(e.message)");
					}

					assign_button.sensitive = true;
				});
			})
			.on_error ((code, message) => {
				warning (@"Error trying to re-assign $report_id: $message $code");
				on_error (@"$message $code");
				assign_button.sensitive = true;
			})
			.exec ();
	}
}
