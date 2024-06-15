public class Tuba.Dialogs.Admin.AddFederationBlock : Dialogs.Admin.Base {
		~AddFederationBlock () {
			debug ("Destroying AddFederationBlock");
		}

		class SeverityObject : Object {
			public API.Admin.DomainBlock.Severity severity { get; set; }

			public SeverityObject (API.Admin.DomainBlock.Severity sev) {
				this.severity = sev;
			}
		}

		public signal void added ();

		Gtk.Button save_button;
		Adw.EntryRow domain_row;
		Adw.ComboRow sev_row;
		GLib.ListStore sev_model;
		Gtk.CheckButton rule_obfuscate;
		Gtk.CheckButton rule_reject_media;
		Gtk.CheckButton rule_reject_reports;
		Adw.ActionRow reject_media_row;
		Adw.ActionRow reject_reports_row;
		Adw.ActionRow obfuscate_row;
		Adw.EntryRow private_comment_row;
		Adw.EntryRow public_comment_row;
		construct {
			this.title = _("Add Federation Block");
			this.content_width = 460;
			this.content_height = 510;
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

			domain_row = new Adw.EntryRow () {
				// translators: Admin dashboard, federation block dialog,
				//				e.g. 'gnome.org'
				title = _("Domain"),
				input_hints = Gtk.InputHints.NO_EMOJI | Gtk.InputHints.NO_SPELLCHECK,
				show_apply_button = false,
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				css_classes = {"error"}
			};
			domain_row.changed.connect (on_domain_changed);

			Gtk.SignalListItemFactory signallistitemfactory = new Gtk.SignalListItemFactory ();
			signallistitemfactory.bind.connect (sev_signal);

			sev_model = new GLib.ListStore (typeof (SeverityObject));
			sev_model.splice (0, 0, {
				new SeverityObject (API.Admin.DomainBlock.Severity.SILENCE),
				new SeverityObject (API.Admin.DomainBlock.Severity.SUSPEND),
				new SeverityObject (API.Admin.DomainBlock.Severity.NOOP),
			});

			sev_row = new Adw.ComboRow () {
				// translators: Admin dashboard, federation block dialog severity row title
				title = _("Severity"),
				model = sev_model,
				factory = signallistitemfactory
			};
			sev_row.notify["selected"].connect (on_sev_change);

			rule_reject_media = new Gtk.CheckButton () {
				active = true,
				css_classes = {"selection-mode"}
			};
			rule_reject_reports = new Gtk.CheckButton () {
				css_classes = {"selection-mode"}
			};
			rule_obfuscate = new Gtk.CheckButton () {
				css_classes = {"selection-mode"}
			};

			reject_media_row = new Adw.ActionRow () {
				// translators: Admin dashboard, federation blocklist, checkbox option title.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				title = _("Reject Media Files"),
				// translators: Admin dashboard, federation blocklist, checkbox option description.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				subtitle = _("Removes locally stored media files and refuses to download any in the future"),
				activatable_widget = rule_reject_media
			};
			reject_media_row.add_prefix (rule_reject_media);

			reject_reports_row = new Adw.ActionRow () {
				// translators: Admin dashboard, federation blocklist, checkbox option title.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				title = _("Reject Reports"),
				// translators: Admin dashboard, federation blocklist, checkbox option description.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				subtitle = _("Ignore all reports coming from this domain"),
				activatable_widget = rule_reject_reports
			};
			reject_reports_row.add_prefix (rule_reject_reports);

			obfuscate_row = new Adw.ActionRow () {
				// translators: Admin dashboard, federation blocklist, checkbox option title.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				title = _("Obfuscate Domain Name"),
				// translators: Admin dashboard, federation blocklist, checkbox option description.
				//				You can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				subtitle = _("Partially obfuscate the domain name in the list if advertising the list of domain limitations is enabled"),
				activatable_widget = rule_obfuscate
			};
			obfuscate_row.add_prefix (rule_obfuscate);

			private_comment_row = new Adw.EntryRow () {
				// translators: Admin dashboard, federation block dialog
				title = _("Private Comment"),
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				show_apply_button = false
			};

			public_comment_row = new Adw.EntryRow () {
				// translators: Admin dashboard, federation block dialog
				title = _("Public Comment"),
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				show_apply_button = false
			};

			var main_group = new Adw.PreferencesGroup ();
			main_group.add (domain_row);
			main_group.add (sev_row);
			main_group.add (reject_media_row);
			main_group.add (reject_reports_row);
			main_group.add (obfuscate_row);
			main_group.add (private_comment_row);
			main_group.add (public_comment_row);

			page.add (main_group);
			on_sev_change ();
		}

		private void on_domain_changed () {
			if (domain_row.text.length > 0) {
				domain_row.remove_css_class ("error");
				save_button.sensitive = true;
			} else {
				domain_row.add_css_class ("error");
				save_button.sensitive = false;
			}
		}

		private void on_sev_change () {
			bool is_suspend = ((SeverityObject) sev_row.selected_item).severity == API.Admin.DomainBlock.Severity.SUSPEND;
			reject_media_row.sensitive = reject_reports_row.sensitive = !is_suspend;
		}

		private void on_cancel () {
			this.force_close ();
		}

		private void on_save () {
			save_button.sensitive = false;

			new Request.POST ("/api/v1/admin/domain_blocks")
				.with_account (accounts.active)
				.with_form_data ("domain", domain_row.text)
				.with_form_data ("severity", ((SeverityObject) sev_row.selected_item).severity.to_api_string ())
				.with_form_data ("public_comment", public_comment_row.text)
				.with_form_data ("private_comment", private_comment_row.text)
				.with_form_data ("obfuscate", rule_obfuscate.active.to_string ())
				.with_form_data ("reject_media", (reject_media_row.sensitive && rule_reject_media.active).to_string ())
				.with_form_data ("reject_reports", (reject_reports_row.sensitive && rule_reject_reports.active).to_string ())
				.then (() => {
					on_domain_changed ();
					added ();
					on_cancel ();
				})
				.on_error ((code, message) => {
					warning (@"Couldn't create federation block $(domain_row.text): $code $message");
					add_toast (message);
				})
				.exec ();
		}

		private void sev_signal (GLib.Object item) {
			((Gtk.ListItem) item).child = new Gtk.Label (((SeverityObject)((Gtk.ListItem) item).item).severity.to_string ());
		}
	}
