public class Tuba.Views.Admin.Page.BlockedEmails : Views.Admin.Page.Base {
	Gtk.Entry child_entry;
	Gtk.Button add_button;
	Views.Admin.Timeline.EmailDomain pagination_timeline;
	construct {
		// translators: Admin Dialog page title,
		//				this is about blocking
		//				e-mail providers like
		//				gmail.com
		this.title = _("Blocked E-mail Domains");

		var add_action_bar = new Gtk.ActionBar () {
			css_classes = { "ttl-box-no-shadow" }
		};

		child_entry = new Gtk.Entry () {
			input_purpose = Gtk.InputPurpose.URL,
			// translators: Admin Dialog entry placeholder text,
			//				this is about blocking e-mail providers like
			//				gmail.com
			placeholder_text = _("Block a new e-mail domain")
		};
		var child_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		add_button = new Gtk.Button.with_label (_("Block")) {
			sensitive = false
		};
		add_button.clicked.connect (new_item_cb);
		child_entry.activate.connect (new_item_cb);
		child_entry.notify["text"].connect (on_entry_changed);

		child_box.append (child_entry);
		child_box.append (add_button);

		add_action_bar.set_center_widget (child_box);
		toolbar_view.add_top_bar (add_action_bar);

		pagination_timeline = new Views.Admin.Timeline.EmailDomain ();
		pagination_timeline.on_error.connect (on_error);
		pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
		this.page = pagination_timeline;

		pagination_timeline.request.begin ();
	}

	void new_item_cb () {
		on_action_bar_activate.begin (child_entry.buffer);
	}

	void on_entry_changed () {
		add_button.sensitive = child_entry.text.length > 0;
	}

	private async void on_action_bar_activate (Gtk.EntryBuffer buffer) {
		if (buffer.length > 0) {
			string domain = buffer.text;
			var dlg = new Adw.AlertDialog (
				// translators: Question dialog when an admin is about to
				//				block an e-mail domain. The variable is a
				//				string.
				_("Block %s?").printf (domain),

				// translators: Question dialog description when an admin is about to
				//				block an e-mail domain. The variable is a string.
				//				you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
				_("This can be the domain name that shows up in the e-mail address or the MX record it uses. They will be checked upon sign-up.")
			);

			dlg.add_response ("no", _("Cancel"));
			dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

			dlg.add_response ("yes", _("Block"));
			dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);

			if ((yield dlg.choose (this.admin_window, null)) == "yes") {
					var req = new RequestV2 ("/api/v1/admin/email_domain_blocks", POST) { account = accounts.active };
					req.add_form_data ("domain", domain);
					try {
						yield req.exec (null);
						yield pagination_timeline.request ();
					} catch (Error e) {
						warning (@"Error trying to block e-mail domain $domain: $(e.message) $(e.code)");
						on_error (e.code, e.message);
					}
			}
		}
		buffer.set_text ("".data);
	}
}
