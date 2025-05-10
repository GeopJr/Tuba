public class Tuba.Dialogs.Admin.Report : Dialogs.Admin.Base {
	public signal void refresh ();

	Adw.PreferencesGroup profile_group;
	Gtk.Button take_action_button;
	Gtk.Button resolve_button;
	construct {
		this.title = _("Report");
		this.content_width = 460;
		this.content_height = 560;
		this.can_close = false;

		profile_group = new Adw.PreferencesGroup ();
		page.add (profile_group);

		this.close_attempt.connect (on_close);
	}

	private void on_action (string title, string suggested_label, string endpoint) {
		var dlg = new Adw.AlertDialog (title, null);

		dlg.add_response ("no", _("Cancel"));
		dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("yes", suggested_label);
		dlg.set_response_appearance ("yes", Adw.ResponseAppearance.SUGGESTED);
		dlg.choose.begin (this, null, (obj, res) => {
			if (dlg.choose.end (res) == "yes") {
				resolve_button.sensitive = false;
				new Request.POST (@"/api/v1/admin/reports/$report_id/$endpoint")
					.with_account (accounts.active)
					.then (() => {
						should_refresh = true;
						on_close ();
					})
					.on_error ((code, message) => {
						warning (@"Error trying to $endpoint report $report_id: $message $code");
						add_toast (@"$message $code");
						resolve_button.sensitive = true;
					})
					.exec ();
			}
		});
	}

	private void on_resolve () {
		on_action (
			// translators: Question dialog when an admin is about to
			//				mark a report as resolved
			_("Mark this Report as Resolved?"),

			_("Resolve"),
			"resolve"
		);
	}

	private void on_reopen () {
		on_action (
			// translators: Question dialog when an admin is about to
			//				reopen a report
			_("Reopen this Report?"),

			_("Reopen"),
			"reopen"
		);
	}

	~Report () {
		debug ("Destroying Report");
		rules_buttons.clear ();
	}

	private void on_assign_row_error (string content) {
		add_toast (content);
	}

	string report_id;
	string account_id;
	string account_handle;
	Gtk.CheckButton rule_other;
	Gtk.CheckButton rule_legal;
	Gtk.CheckButton rule_violation;
	Gtk.CheckButton rule_spam;
	Adw.PreferencesGroup rules_group;
	Adw.ActionRow rule_other_row;
	Adw.ActionRow rule_legal_row;
	Adw.ActionRow rule_violation_row;
	Adw.ActionRow rule_spam_row;
	Gee.HashMap<string, Gtk.CheckButton> rules_buttons;
	public Report (API.Admin.Report report) {
		report_id = report.id;
		account_id = report.target_account.account.id;
		account_handle = report.target_account.account.full_handle;
		// translators: Admin dashboard, take action against user headerbar button
		take_action_button = new Gtk.Button.with_label (_("Take Action")) {
			css_classes = {"destructive-action"},
			sensitive = !report.action_taken
		};
		take_action_button.clicked.connect (show_take_action_dialog);

		resolve_button = new Gtk.Button.with_label (report.action_taken ? _("Reopen") : _("Resolve")) {
			css_classes = {"suggested-action"}
		};

		if (report.action_taken) {
			resolve_button.clicked.connect (on_reopen);
		} else {
			resolve_button.clicked.connect (on_resolve);
		}

		headerbar.pack_end (take_action_button);
		headerbar.pack_start (resolve_button);

		try {
			Widgets.Account profile = (Widgets.Account) report.target_account.account.to_widget ();
			profile.overflow = Gtk.Overflow.HIDDEN;
			profile.disable_profile_open = true;
			profile.add_css_class ("card");
			profile_group.add (profile);
		} catch {}

		var info_group = new Adw.PreferencesGroup ();
		if (report.target_account.account.created_at != null) {
			var join_date = new GLib.DateTime.from_iso8601 (report.target_account.account.created_at, null);
			join_date = join_date.to_timezone (new TimeZone.local ());
			info_group.add (new Adw.ActionRow () {
				title = _("Joined"),
				subtitle = join_date.format (_("%B %e, %Y")).replace (" ", ""),
				subtitle_selectable = true
			});
		}

		info_group.add (new Adw.ActionRow () {
			title = _("Reported on"),
			subtitle = new GLib.DateTime.from_iso8601 (report.created_at, null).format ("%F %T"),
			subtitle_selectable = true
		});

		info_group.add (new Adw.ActionRow () {
			title = _("Reported by"),
			subtitle = report.account.account.full_handle,
			subtitle_selectable = true
		});

		info_group.add (new Adw.ActionRow () {
			title = _("Status"),
			subtitle = report.action_taken ? _("Resolved") : _("Unresolved"),
			subtitle_selectable = true
		});

		if (report.forwarded == true) {
			info_group.add (new Adw.ActionRow () {
				// translators: admin dashboard, whether a report was 'forwarded' from another server
				title = _("Forwarded")
			});
		}

		if (report.action_taken_by_account != null) {
			info_group.add (new Adw.ActionRow () {
				title = _("Action Taken by"),
				subtitle = report.action_taken_by_account.account.full_handle,
				subtitle_selectable = true
			});
		} else {
			var row = new Widgets.Admin.AssignedToRow (report.id, report.assigned_account);
			row.on_error.connect (on_assign_row_error);
			row.assignment_changed.connect (mark_for_refresh);
			info_group.add (row);
		}

		var rule_group = new Adw.PreferencesGroup () {
			title = _("Category"),
			// translators: Admin dashboard report category description.
			//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			description = _("The reason this account and/or content was reported will be cited in communication with the reported account")
		};

		var report_category = API.Admin.Report.Category.from_string (report.category);
		rule_other = new Gtk.CheckButton () {
			active = report_category == API.Admin.Report.Category.OTHER,
			css_classes = {"selection-mode"}
		};
		rule_other.toggled.connect (update_report);
		rule_legal = new Gtk.CheckButton () {
			group = rule_other,
			active = report_category == API.Admin.Report.Category.LEGAL,
			css_classes = {"selection-mode"}
		};
		rule_legal.toggled.connect (update_report);
		rule_spam = new Gtk.CheckButton () {
			group = rule_other,
			active = report_category == API.Admin.Report.Category.SPAM,
			css_classes = {"selection-mode"}
		};
		rule_spam.toggled.connect (update_report);
		rule_violation = new Gtk.CheckButton () {
			group = rule_other,
			active = report_category == API.Admin.Report.Category.VIOLATION,
			css_classes = {"selection-mode"}
		};
		rule_violation.toggled.connect (update_report);

		rule_other_row = new Adw.ActionRow () {
			title = API.Admin.Report.Category.OTHER.to_string (),
			activatable_widget = rule_other,
			sensitive = !report.action_taken
		};
		rule_other_row.add_prefix (rule_other);

		rule_legal_row = new Adw.ActionRow () {
			title = API.Admin.Report.Category.LEGAL.to_string (),
			activatable_widget = rule_legal,
			sensitive = !report.action_taken
		};
		rule_legal_row.add_prefix (rule_legal);

		rule_spam_row = new Adw.ActionRow () {
			title = API.Admin.Report.Category.SPAM.to_string (),
			activatable_widget = rule_spam,
			sensitive = !report.action_taken
		};
		rule_spam_row.add_prefix (rule_spam);

		rule_violation_row = new Adw.ActionRow () {
			title = API.Admin.Report.Category.VIOLATION.to_string (),
			activatable_widget = rule_violation,
			sensitive = !report.action_taken
		};
		rule_violation_row.add_prefix (rule_violation);

		rule_group.add (rule_other_row);
		rule_group.add (rule_legal_row);
		rule_group.add (rule_spam_row);
		rule_group.add (rule_violation_row);

		rules_group = new Adw.PreferencesGroup () {
			title = _("Violated Rules"),
			visible = report_category == API.Admin.Report.Category.VIOLATION
		};

		if (accounts.active.instance_info.rules != null && accounts.active.instance_info.rules.size > 0) {
			rules_buttons = new Gee.HashMap<string, Gtk.CheckButton> ();
			string[] selected_rules_ids = {};
			foreach (var rule in report.rules) {
				selected_rules_ids += rule.id;
			}

			foreach (var rule in accounts.active.instance_info.rules) {
				var checkbutton = new Gtk.CheckButton () {
					css_classes = {"selection-mode"},
					active = rule.id in selected_rules_ids
				};
				checkbutton.toggled.connect (update_report);
				rules_buttons.set (rule.id, checkbutton);

				var rule_row = new Adw.ActionRow () {
					title = GLib.Markup.escape_text (rule.text).strip (),
					activatable_widget = checkbutton,
					use_markup = true,
					sensitive = !report.action_taken
				};
				rule_row.add_prefix (checkbutton);
				rules_group.add (rule_row);
			}
		}

		var status_group = new Adw.PreferencesGroup () {
			title = _("Reported Posts")
		};

		report.statuses.foreach (status => {
			try {
				status.formal.filtered = null;
				status.formal.tuba_spoiler_revealed = true;
				if (status.formal.has_media) {
					status.formal.media_attachments.foreach (e => {
						e.tuba_is_report = true;

						return true;
					});
				}
				Widgets.Status widget = (Widgets.Status) status.to_widget ();
				widget.add_css_class ("report-status");
				widget.add_css_class ("card");
				widget.add_css_class ("card-spacing");
				widget.actions.visible = false;
				widget.menu_button.visible = false;
				widget.activatable = false;
				widget.filter_stack.can_focus = false;
				widget.filter_stack.can_target = false;
				widget.filter_stack.focusable = false;

				status_group.add (widget);
			} catch {}

			return true;
		});

		page.add (info_group);
		page.add (rule_group);
		page.add (rules_group);
		page.add (status_group);
	}

	private void update_report () {
		string[] rule_ids = {};
		string? category = null;

		// Mastodon is broken. If you change category while there have been rules
		// applied, it won't allow you to. Let's clear them first.
		if (!rule_violation.active && rules_group.visible) {
			update_report_actual (API.Admin.Report.Category.VIOLATION.to_api_string (), rule_ids);
		}

		if (rule_violation.active) {
			rules_buttons.foreach (e => {
				if (((Gtk.CheckButton) e.value).active) {
					rule_ids += (string) e.key;
				}
				return true;
			});
			category = API.Admin.Report.Category.VIOLATION.to_api_string ();
			rules_group.visible = true;
		} else if (rule_spam.active) {
			category = API.Admin.Report.Category.SPAM.to_api_string ();
			rules_group.visible = false;
		} else if (rule_legal.active) {
			category = API.Admin.Report.Category.LEGAL.to_api_string ();
			rules_group.visible = false;
		} else if (rule_other.active) {
			category = API.Admin.Report.Category.OTHER.to_api_string ();
			rules_group.visible = false;
		}

		if (category != null)
			update_report_actual (category, rule_ids);
	}

	private void update_report_actual (string category, string[] rule_ids) {
		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("category");
		builder.add_string_value (category);

		builder.set_member_name ("rule_ids");
		builder.begin_array ();
		foreach (string rule_id in rule_ids) {
			builder.add_string_value (rule_id);
		}
		builder.end_array ();

		builder.end_object ();

		should_refresh = true;
		new Request.PUT (@"/api/v1/admin/reports/$report_id")
			.body_json (builder)
			.with_account (accounts.active)
			.on_error ((code, message) => {
				warning (@"Error trying to update report $report_id: $message $code");
				add_toast (@"$message $code");
				resolve_button.sensitive = true;
			})
			.exec ();
	}

	private void show_take_action_dialog () {
		var dlg = new Dialogs.Admin.TakeAction (account_id, account_handle, report_id);
		dlg.took_action.connect (on_took_action);
		dlg.present (this);
	}

	private void on_took_action () {
		should_refresh = true;
		on_close ();
	}

	bool should_refresh = false;
	private void mark_for_refresh () {
		should_refresh = true;
	}

	private void on_close () {
		if (should_refresh) refresh ();
		this.force_close ();
	}
}
