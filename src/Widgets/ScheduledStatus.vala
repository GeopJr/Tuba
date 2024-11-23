public class Tuba.Widgets.ScheduledStatus : Gtk.ListBoxRow {
	public signal void deleted (string scheduled_status_id);
	public signal void open ();

	private bool _draft = false;
	public bool draft {
		get { return _draft; }
		set {
			_draft = value;
			reschedule_button.visible = !value;
			schedule_label.label = "<b>%s</b>".printf (_("Draft"));
			this.activatable = value;
		}
	}

	Gtk.Button reschedule_button;
	Gtk.Box content_box;
	Gtk.Label schedule_label;
	construct {
		this.focusable = true;
		this.activatable = false;
		this.css_classes = { "card-spacing", "card" };
		this.overflow = Gtk.Overflow.HIDDEN;

		content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		var action_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
			margin_top = margin_bottom = margin_start = margin_end = 6
		};
		schedule_label = new Gtk.Label ("") {
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			use_markup = true,
			xalign = 0.0f,
			hexpand = true,
			margin_start = 6
		};
		action_box.append (schedule_label);

		var actions_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		reschedule_button = new Gtk.Button.from_icon_name ("tuba-clock-alt-symbolic") {
			tooltip_text = _("Reschedule"),
			css_classes = { "flat" }
		};
		reschedule_button.clicked.connect (on_reschedule);
		actions_box.append (reschedule_button);

		Gtk.Button delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
			css_classes = { "flat", "error" },
			tooltip_text = _("Delete"),
			valign = Gtk.Align.CENTER
		};
		delete_button.clicked.connect (on_delete);
		actions_box.append (delete_button);
		action_box.append (actions_box);

		content_box.append (action_box);
		this.child = content_box;

		open.connect (on_activated);
	}

	public ScheduledStatus (API.ScheduledStatus scheduled_status) {
		Object ();
		bind (scheduled_status);
	}

	string scheduled_at;
	string scheduled_id;
	Widgets.Status? status_widget = null;
	public void bind (API.ScheduledStatus scheduled_status) {
		if (status_widget != null) content_box.remove (status_widget);

		scheduled_at = scheduled_status.scheduled_at;
		scheduled_id = scheduled_status.id;

		API.Poll? poll = null;
		if (scheduled_status.props.poll != null) {
			poll = new API.Poll ("0") {
				multiple = scheduled_status.props.poll.multiple,
				options = new Gee.ArrayList<API.PollOption> ()
			};

			foreach (string poll_option in scheduled_status.props.poll.options) {
				poll.options.add (new API.PollOption () {
					title = poll_option,
					votes_count = 0
				});
			}

			poll.expires_at = new GLib.DateTime.now_local ().add_seconds (scheduled_status.props.poll.expires_in).format_iso8601 ();
		}

		var status = new API.Status.empty () {
			account = accounts.active,
			spoiler_text = scheduled_status.props.spoiler_text,
			content = scheduled_status.props.text,
			sensitive = scheduled_status.props.sensitive,
			visibility = scheduled_status.props.visibility,
			media_attachments = scheduled_status.media_attachments,
			tuba_spoiler_revealed = true,
			poll = poll,
			created_at = scheduled_status.scheduled_at
		};

		if (scheduled_status.props.language != null) status.language = scheduled_status.props.language;

		var widg = new Widgets.Status (status);
		widg.can_be_opened = false;
		widg.activatable = false;
		widg.actions.visible = false;
		widg.menu_button.visible = false;
		widg.date_label.visible = false;
		if (widg.poll != null) {
			widg.poll.usable = false;
			widg.poll.info_label.label = DateTime.humanize_ago (poll.expires_at);
		}

		// Re-parse the date into a MONTH DAY, YEAR (separator) HOUR:MINUTES
		var date_parsed = new GLib.DateTime.from_iso8601 (scheduled_status.scheduled_at, null);
		date_parsed = date_parsed.to_timezone (new TimeZone.local ());
		var date_local = _("%B %e, %Y");
		// translators: Scheduled Post title, 'scheduled for: <date>'
		schedule_label.label = "<b>%s</b> %s".printf (
			_("Scheduled For:"),
			date_parsed.format (@"$date_local · %H:%M").replace (" ", "") // %e prefixes with whitespace on single digits
		);

		content_box.append (widg);
		status_widget = widg;
	}

	private void on_reschedule () {
		var schedule_dlg = new Dialogs.Schedule (scheduled_at, _("Reschedule"));
		schedule_dlg.schedule_picked.connect (on_schedule_picked);
		schedule_dlg.present (this);
	}

	private void on_schedule_picked (string iso8601) {
		new Request.PUT (@"/api/v1/scheduled_statuses/$scheduled_id")
			.with_account (accounts.active)
			.with_form_data ("scheduled_at", iso8601)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				var e = Tuba.Helper.Entity.from_json (node, typeof (API.ScheduledStatus), true);
				if (e is API.ScheduledStatus) bind ((API.ScheduledStatus) e);
			})
			.on_error ((code, message) => {
				warning (@"Error while rescheduling: $code $message");

				// translators: the variable is an error
				app.toast (_("Couldn't reschedule: %s").printf (message), 0);
			})
			.exec ();
	}

	private void on_delete () {
		string title = !_draft
			? _("Delete Scheduled Post?")
			// translators: 'Draft' is not a verb here.
			//				It's equal to 'Unsaved'
			: _("Delete Draft Post?");

		app.question.begin (
			{title, false},
			null,
			app.main_window,
			{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			null,
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) {
					delete_status ();
				}
			}
		);
	}

	private void delete_status () {
		new Request.DELETE (@"/api/v1/scheduled_statuses/$scheduled_id")
			.with_account (accounts.active)
			.then (() => {
				deleted (scheduled_id);
			})
			.on_error ((code, message) => {
				warning (@"Error while deleting scheduled status: $code $message");
				app.toast (message, 0);
			})
			.exec ();
	}

	private void on_activated () {
		if (!_draft || status_widget == null) return;

		new Dialogs.Compose.from_draft (status_widget.status, on_draft_posted);
	}

	private void on_draft_posted (API.Status x) {
		if (_draft) delete_status ();
	}
}
