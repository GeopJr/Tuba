public class Tuba.Dialogs.TmpAdmin.AddIPBlock : Dialogs.TmpAdmin.Base {
		~AddIPBlock () {
			debug ("Destroying AddIPBlock");
		}

		enum Expiration {
			DAY_1,
			WEEK_2,
			MONTH_1,
			MONTH_6,
			YEAR_1,
			YEAR_3;

			public string to_string () {
				switch (this) {
					case YEAR_3:
						return GLib.ngettext ("%d Year", "%d Years", (ulong) 3).printf (3);
					case YEAR_1:
						return GLib.ngettext ("%d Year", "%d Years", (ulong) 1).printf (1);
					case MONTH_6:
						return GLib.ngettext ("%d Month", "%d Months", (ulong) 6).printf (6);
					case MONTH_1:
						return GLib.ngettext ("%d Month", "%d Months", (ulong) 1).printf (1);
					case WEEK_2:
						return GLib.ngettext ("%d Week", "%d Weeks", (ulong) 2).printf (2);
					default:
						return GLib.ngettext ("%d Day", "%d Days", (ulong) 1).printf (1);
				}
			}

			public int to_seconds () {
				switch (this) {
					case YEAR_3:
						return 94608000;
					case YEAR_1:
						return 31536000;
					case MONTH_6:
						return 15780000;
					case MONTH_1:
						return 2630000;
					case WEEK_2:
						return 1209600;
					default:
						return 86400;
				}
			}
		}

		class ExpirationObject : Object {
			public Expiration expiration { get; set; }

			public ExpirationObject (Expiration exp) {
				this.expiration = exp;
			}
		}

		public signal void added ();

		Gtk.Button save_button;
		Adw.EntryRow ip_row;
		Adw.ComboRow exp_row;
		GLib.ListStore exp_model;
		Gtk.CheckButton rule_no_access;
		Gtk.CheckButton rule_signup_block;
		Gtk.CheckButton rule_signup_approve;
		Adw.EntryRow comment_row;
		construct {
			this.title = _("Add IP Block");
			this.content_width = 460;
			this.content_height = 502;
			this.can_close = false;

			headerbar.show_end_title_buttons = false;
			headerbar.show_start_title_buttons = false;

			var cancel_button = new Gtk.Button.with_label (_("Cancel"));
			cancel_button.clicked.connect (on_cancel);

			save_button = new Gtk.Button.with_label (_("Add")) {
				css_classes = { "suggested-action" },
				sensitive = false
			};
			save_button.clicked.connect (on_save);

			headerbar.pack_start (cancel_button);
			headerbar.pack_end (save_button);

			ip_row = new Adw.EntryRow () {
				title = "192.0.2.0/24",
				input_hints = Gtk.InputHints.NO_EMOJI | Gtk.InputHints.NO_SPELLCHECK,
				show_apply_button = false,
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				css_classes = {"error"}
			};
			ip_row.changed.connect (on_ip_changed);

			comment_row = new Adw.EntryRow () {
				// translators: Admin dashboard ip block comment entry title
				title = _("Comment"),
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				show_apply_button = false
			};

			var ip_group = new Adw.PreferencesGroup ();
			ip_group.add (ip_row);
			ip_group.add (comment_row);

			Gtk.SignalListItemFactory signallistitemfactory = new Gtk.SignalListItemFactory ();
			signallistitemfactory.bind.connect (exp_signal);

			exp_model = new GLib.ListStore (typeof (ExpirationObject));
			exp_model.splice (0, 0, {
				new ExpirationObject (Expiration.DAY_1),
				new ExpirationObject (Expiration.WEEK_2),
				new ExpirationObject (Expiration.MONTH_1),
				new ExpirationObject (Expiration.MONTH_6),
				new ExpirationObject (Expiration.YEAR_1),
				new ExpirationObject (Expiration.YEAR_3)
			});

			exp_row = new Adw.ComboRow () {
				// translators: Admin dashboard ip block expiration date row title.
				title = _("Expiration"),
				model = exp_model,
				factory = signallistitemfactory
			};
			ip_group.add (exp_row);

			var rule_group = new Adw.PreferencesGroup () {
				// translators: Admin dashboard ip block rule (e.g. no access)
				title = _("Rule"),
				// translators: Admin dashboard ip block rule descriptions.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				description = _("Choose what will happen with requests from this IP")
			};

			rule_no_access = new Gtk.CheckButton () {
				active = true,
				css_classes = {"selection-mode"}
			};
			rule_signup_block = new Gtk.CheckButton () {
				group = rule_no_access,
				css_classes = {"selection-mode"}
			};
			rule_signup_approve = new Gtk.CheckButton () {
				group = rule_no_access,
				css_classes = {"selection-mode"}
			};

			var action_row = new Adw.ActionRow () {
				title = API.Admin.IPBlock.Severity.NO_ACCESS.to_title (),
				subtitle = API.Admin.IPBlock.Severity.NO_ACCESS.to_descritpion (),
				activatable_widget = rule_no_access
			};
			action_row.add_prefix (rule_no_access);
			rule_group.add (action_row);

			action_row = new Adw.ActionRow () {
				title = API.Admin.IPBlock.Severity.SIGN_UP_BLOCK.to_title (),
				subtitle = API.Admin.IPBlock.Severity.SIGN_UP_BLOCK.to_descritpion (),
				activatable_widget = rule_signup_block
			};
			action_row.add_prefix (rule_signup_block);
			rule_group.add (action_row);

			action_row = new Adw.ActionRow () {
				title = API.Admin.IPBlock.Severity.SIGN_UP_REQUIRES_APPROVAL.to_title (),
				subtitle = API.Admin.IPBlock.Severity.SIGN_UP_REQUIRES_APPROVAL.to_descritpion (),
				activatable_widget = rule_signup_approve
			};
			action_row.add_prefix (rule_signup_approve);
			rule_group.add (action_row);

			page.add (ip_group);
			page.add (rule_group);
		}

		private void on_ip_changed () {
			if (ip_row.text.length > 0) {
				ip_row.remove_css_class ("error");
				save_button.sensitive = true;
			} else {
				ip_row.add_css_class ("error");
				save_button.sensitive = false;
			}
		}

		private void on_cancel () {
			this.force_close ();
		}

		private void on_save () {
			save_button.sensitive = false;

			API.Admin.IPBlock.Severity sev = API.Admin.IPBlock.Severity.NO_ACCESS;
			if (rule_signup_approve.active) {
				sev = API.Admin.IPBlock.Severity.SIGN_UP_REQUIRES_APPROVAL;
			} else if (rule_signup_block.active) {
				sev = API.Admin.IPBlock.Severity.SIGN_UP_BLOCK;
			}

			new Request.POST ("/api/v1/admin/ip_blocks")
				.with_account (accounts.active)
				.with_form_data ("ip", ip_row.text)
				.with_form_data ("severity", sev.to_api_string ())
				.with_form_data ("expires_in", ((ExpirationObject) exp_row.selected_item).expiration.to_seconds ().to_string ())
				.with_form_data ("comment", comment_row.text)
				.then (() => {
					on_ip_changed ();
					added ();
					on_cancel ();
				})
				.on_error ((code, message) => {
					warning (@"Couldn't create IP block $(ip_row.text): $code $message");
					add_toast (message);
				})
				.exec ();
		}

		private void exp_signal (GLib.Object item) {
			((Gtk.ListItem) item).child = new Gtk.Label (((ExpirationObject)((Gtk.ListItem) item).item).expiration.to_string ());
		}
	}
