public class Tuba.Dialogs.Admin.TakeAction : Dialogs.Admin.Base {
	public signal void took_action ();

	~TakeAction () {
		debug ("Destroying TakeAction");
	}

	Gtk.Button take_action_button;
	Gtk.CheckButton action_warning;
	Gtk.CheckButton action_freeze;
	Gtk.CheckButton action_sensitive;
	Gtk.CheckButton action_limit;
	Gtk.CheckButton action_suspend;

	Gtk.CheckButton send_email;
	Adw.EntryRow comment_row;
	construct {
		this.title = _("Take Action");
		this.content_width = 460;
		this.content_height = 500;

		var cancel_button = new Gtk.Button.with_label (_("Cancel"));
		cancel_button.clicked.connect (on_cancel);

		take_action_button = new Gtk.Button.with_label (_("Submit")) {
			css_classes = {"destructive-action"}
		};
		take_action_button.clicked.connect (on_take_action);

		headerbar.show_end_title_buttons = false;
		headerbar.show_start_title_buttons = false;

		headerbar.pack_start (cancel_button);
		headerbar.pack_end (take_action_button);

		var action_group = new Adw.PreferencesGroup ();
		action_warning = new Gtk.CheckButton () {
			active = true,
			css_classes = {"selection-mode"}
		};
		action_freeze = new Gtk.CheckButton () {
			group = action_warning,
			css_classes = {"selection-mode"}
		};
		action_sensitive = new Gtk.CheckButton () {
			group = action_warning,
			css_classes = {"selection-mode"}
		};
		action_limit = new Gtk.CheckButton () {
			group = action_warning,
			css_classes = {"selection-mode"}
		};
		action_suspend = new Gtk.CheckButton () {
			group = action_warning,
			css_classes = {"selection-mode"}
		};

		var action_row = new Adw.ActionRow () {
			title = _("Warning"),
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			subtitle = _("Use this to send a warning to the user, without triggering any other action"),
			activatable_widget = action_warning
		};
		action_row.add_prefix (action_warning);
		action_group.add (action_row);

		action_row = new Adw.ActionRow () {
			title = _("Freeze"),
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			subtitle = _("Prevent the user from using their account, but do not delete or hide their contents"),
			activatable_widget = action_freeze
		};
		action_row.add_prefix (action_freeze);
		action_group.add (action_row);

		action_row = new Adw.ActionRow () {
			title = _("Sensitive"),
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			subtitle = _("Force all this user's media attachments to be flagged as sensitive"),
			activatable_widget = action_sensitive
		};
		action_row.add_prefix (action_sensitive);
		action_group.add (action_row);

		action_row = new Adw.ActionRow () {
			title = _("Limit"),
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			subtitle = _("Prevent the user from being able to post with public visibility, hide their posts and notifications from people not following them. Closes all reports against this account"),
			activatable_widget = action_limit
		};
		action_row.add_prefix (action_limit);
		action_group.add (action_row);

		action_row = new Adw.ActionRow () {
			title = _("Suspend"),
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			subtitle = _("Prevent any interaction from or to this account and delete its contents. Revertible within 30 days. Closes all reports against this account"),
			activatable_widget = action_suspend
		};
		action_row.add_prefix (action_suspend);
		action_group.add (action_row);

		comment_row = new Adw.EntryRow () {
			title = _("Comment")
		};
		action_group.add (comment_row);

		send_email = new Gtk.CheckButton () {
			active = true,
			css_classes = {"selection-mode"}
		};
		action_row = new Adw.ActionRow () {
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			title = _("Notify the user per e-mail"),
			// translators: admin dashboard, you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
			subtitle = _("The user will receive an explanation of what happened with their account"),
			activatable_widget = send_email
		};
		action_row.add_prefix (send_email);
		action_group.add (action_row);

		page.add (action_group);
	}

	string account_id;
	string? report_id = null;
	public TakeAction (string account_id, string? report_id = null) {
		this.account_id = account_id;
		this.report_id = report_id;
	}

	private void on_cancel () {
		this.force_close ();
	}

	private void on_take_action () {
		var dlg = new Adw.AlertDialog (
			// translators: Question dialog when an admin is about to
			//				take action against an account
			_("Are you sure you want to proceed?"),
			null
		);

		dlg.add_response ("no", _("Cancel"));
		dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("yes", _("Take Action"));
		dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
		dlg.choose.begin (this, null, (obj, res) => {
			if (dlg.choose.end (res) == "yes") {
				this.sensitive = false;

				string kind = "none";
				if (action_freeze.active) {
					kind = "disable";
				} else if (action_sensitive.active) {
					kind = "sensitive";
				} else if (action_limit.active) {
					kind = "silence";
				} else if (action_suspend.active) {
					kind = "suspend";
				}

				var req = new Request.POST (@"/api/v1/admin/accounts/$account_id/action")
					.with_account (accounts.active)
					.with_form_data ("type", kind)
					.with_form_data ("text", comment_row.text)
					.with_form_data ("send_email_notification", send_email.active.to_string ())
					.then (() => {
						on_cancel ();
						took_action ();
					})
					.on_error ((code, message) => {
						this.sensitive = true;
						warning (@"Couldn't perform action $kind: $code $message");
						add_toast (@"$message $code");
					});

				if (report_id != null) req.with_form_data ("report_id", report_id);

				req.exec ();
			}
		});
	}
}
