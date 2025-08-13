public class Tuba.Views.Admin.Page.Accounts : Views.Admin.Page.Base {
	class DropDownStringEntry : Object {
		public string api { get; set; }
		public string title { get; set; }

		public DropDownStringEntry (string api, string title) {
			this.api = api;
			this.title = title;
		}
	}

	Gtk.Entry username_entry;
	Gtk.Entry display_name_entry;
	Gtk.Entry ip_entry;
	Gtk.Entry email_entry;
	Views.Admin.Timeline.Accounts pagination_timeline;
	Gtk.Revealer revealer;
	Gtk.ToggleButton search_button;
	Gtk.DropDown location_dropdown;
	Gtk.DropDown moderation_dropdown;
	construct {
		this.title = _("Accounts");

		search_button = new Gtk.ToggleButton () {
			tooltip_text = _("Search"),
			css_classes = {"flat"},
			icon_name = "tuba-loupe-large-symbolic"
		};
		search_button.toggled.connect (on_search_button_toggle);
		headerbar.pack_end (search_button);

		var revealer_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
			margin_start = 6,
			margin_end = 6,
			margin_bottom = 3,
			halign = Gtk.Align.CENTER
		};
		var entry_box_1 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		var entry_box_2 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		var dropdown_box_1 = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6) {
			homogeneous = true
		};
		revealer_box.append (dropdown_box_1);
		revealer_box.append (entry_box_1);
		revealer_box.append (entry_box_2);

		var breakpoint_bin = new Adw.BreakpointBin () {
			child = revealer_box,
			width_request = 5,
			height_request = 5,
		};
		var condition = new Adw.BreakpointCondition.length (
			Adw.BreakpointConditionLengthType.MAX_WIDTH,
			450, Adw.LengthUnit.SP
		);
		var breakpoint = new Adw.Breakpoint (condition.copy());
		breakpoint.add_setter (revealer_box, "halign", Gtk.Align.FILL);
		breakpoint.add_setter (entry_box_1, "orientation", Gtk.Orientation.VERTICAL);
		breakpoint.add_setter (entry_box_2, "orientation", Gtk.Orientation.VERTICAL);
		breakpoint.add_setter (dropdown_box_1, "orientation", Gtk.Orientation.VERTICAL);
		breakpoint_bin.add_breakpoint (breakpoint);

		Gtk.SignalListItemFactory signallistitemfactory_location = new Gtk.SignalListItemFactory ();
		signallistitemfactory_location.bind.connect (dropdown_signal);

		var location_model = new GLib.ListStore (typeof (DropDownStringEntry));
		location_model.splice (0, 0, {
			new DropDownStringEntry ("all", _("All")),
			new DropDownStringEntry ("local", _("Local")),
			// translators: Dropdown entry, remote as in from a different instance.
			//				It's for the admin dashboard, so it's better if it stays
			//				close to the original word.
			new DropDownStringEntry ("remote", _("Remote")),
		});

		location_dropdown = new Gtk.DropDown (location_model, null) {
			// translators: admin panel, accounts tab, filter dropdown tooltip text
			tooltip_text = _("Location"),
			factory = signallistitemfactory_location,
			show_arrow = true,
			hexpand = true
		};
		location_dropdown.notify["selected"].connect (on_search);
		dropdown_box_1.append (location_dropdown);

		Gtk.SignalListItemFactory signallistitemfactory_moderation = new Gtk.SignalListItemFactory ();
		signallistitemfactory_moderation.bind.connect (dropdown_signal);

		var moderation_model = new GLib.ListStore (typeof (DropDownStringEntry));
		moderation_model.splice (0, 0, {
			new DropDownStringEntry ("all", _("All")),
			// translators: Dropdown entry, account status.
			//				It's for the admin dashboard, so it's better if it stays
			//				close to the original word.
			new DropDownStringEntry ("active", _("Active")),
			//  new DropDownStringEntry ("sensitized", _("Sensitive")), // doesn't seem to work on Mastodon

			// translators: Dropdown entry, account status.
			//				It's for the admin dashboard, so it's better if it stays
			//				close to the original word.
			new DropDownStringEntry ("silenced", _("Limited")),
			// translators: Dropdown entry, account status.
			//				It's for the admin dashboard, so it's better if it stays
			//				close to the original word.
			new DropDownStringEntry ("disabled", _("Disabled")),
			// translators: Dropdown entry, account status.
			//				It's for the admin dashboard, so it's better if it stays
			//				close to the original word.
			new DropDownStringEntry ("suspended", _("Suspended")),
			// translators: Dropdown entry, account status.
			//				It's for the admin dashboard, so it's better if it stays
			//				close to the original word.
			new DropDownStringEntry ("pending", _("Pending")),
		});

		moderation_dropdown = new Gtk.DropDown (moderation_model, null) {
			// translators: admin panel, accounts tab, filter dropdown tooltip text
			tooltip_text = _("Moderation"),
			factory = signallistitemfactory_moderation,
			show_arrow = true,
			hexpand = true
		};
		moderation_dropdown.notify["selected"].connect (on_search);
		dropdown_box_1.append (moderation_dropdown);

		username_entry = new Gtk.Entry () {
			input_purpose = Gtk.InputPurpose.URL,
			placeholder_text = _("Username")
		};
		username_entry.activate.connect (on_search);
		entry_box_1.append (username_entry);

		display_name_entry = new Gtk.Entry () {
			input_purpose = Gtk.InputPurpose.URL,
			placeholder_text = _("Display Name")
		};
		display_name_entry.activate.connect (on_search);
		entry_box_1.append (display_name_entry);

		email_entry = new Gtk.Entry () {
			input_purpose = Gtk.InputPurpose.URL,
			placeholder_text = _("E-mail")
		};
		email_entry.activate.connect (on_search);
		entry_box_2.append (email_entry);

		ip_entry = new Gtk.Entry () {
			input_purpose = Gtk.InputPurpose.URL,
			placeholder_text = "IP" // don't translate
		};
		ip_entry.activate.connect (on_search);
		entry_box_2.append (ip_entry);

		revealer = new Gtk.Revealer () {
			child = breakpoint_bin
		};
		toolbar_view.add_top_bar (revealer);

		pagination_timeline = new Views.Admin.Timeline.Accounts ();
		pagination_timeline.on_open_account.connect (show_account_dialog);
		pagination_timeline.on_error.connect (on_error);
		pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
		this.page = pagination_timeline;

		refresh ();
	}

	private void on_search_button_toggle () {
		revealer.reveal_child = search_button.active;
	}

	private void on_search () {
		string[] qparams = {};

		if (username_entry.text != "") {
			qparams += @"username=$(Uri.escape_string(username_entry.text))";
		}

		if (display_name_entry.text != "") {
			qparams += @"display_name=$(Uri.escape_string(display_name_entry.text))";
		}

		if (email_entry.text != "") {
			qparams += @"email=$(Uri.escape_string(email_entry.text))";
		}

		if (ip_entry.text != "") {
			qparams += @"ip=$(Uri.escape_string(ip_entry.text))";
		}

		if (location_dropdown.selected > 0) {
			qparams += @"$(((DropDownStringEntry) location_dropdown.selected_item).api)=true";
		}

		if (moderation_dropdown.selected > 0) {
			qparams += @"$(((DropDownStringEntry) moderation_dropdown.selected_item).api)=true";
		}

		string endpoint = qparams.length > 0 ? @"?$(string.joinv ("&", qparams))" : "";
		pagination_timeline.reset (@"/api/v1/admin/accounts$endpoint");
	}

	private void refresh () {
		pagination_timeline.request_idle ();
	}

	private void dropdown_signal (GLib.Object item) {
		((Gtk.ListItem) item).child = new Gtk.Label (((DropDownStringEntry)((Gtk.ListItem) item).item).title) {
			ellipsize = Pango.EllipsizeMode.END
		};
	}

	private void show_account_dialog (API.Admin.Account account) {
		var dlg = new AccountDialog (account);
		dlg.refresh.connect (refresh);
		dlg.present (this);
	}

	class AccountDialog : Adw.Dialog {
		public signal void refresh ();

		~AccountDialog () {
			debug ("Destroying AccountDialog");
		}

		Adw.PreferencesPage page;
		Adw.ToastOverlay toast_overlay;
		construct {
			this.content_width = 460;
			this.content_height = 510;
			this.can_close = false;

			page = new Adw.PreferencesPage ();
			toast_overlay = new Adw.ToastOverlay () {
				vexpand = true,
				hexpand = true,
				child = page
			};

			var toolbarview = new Adw.ToolbarView () {
				content = toast_overlay,
				valign = Gtk.Align.CENTER
			};

			var headerbar = new Adw.HeaderBar () {
				show_end_title_buttons = false,
				show_start_title_buttons = false
			};

			var take_action_button = new Gtk.Button.with_label (_("Take Action")) {
				css_classes = {"destructive-action"}
			};
			take_action_button.clicked.connect (show_take_action_dialog);
			headerbar.pack_end (take_action_button);

			var cancel_button = new Gtk.Button.with_label (_("Cancel"));
			cancel_button.clicked.connect (on_close);
			headerbar.pack_start (cancel_button);

			toolbarview.add_top_bar (headerbar);

			this.child = toolbarview;
		}

		string account_id;
		string account_handle;
		Adw.ActionRow? approval_row = null;
		public AccountDialog (API.Admin.Account account) {
			account_id = account.account.id;
			account_handle = account.account.full_handle;
			this.title = account.account.full_handle;

			var profile_group = new Adw.PreferencesGroup ();
			page.add (profile_group);

			Widgets.Account profile = (Widgets.Account) account.account.to_widget ();
			profile.overflow = Gtk.Overflow.HIDDEN;
			profile.disable_profile_open = true;
			profile.add_css_class ("card");
			profile_group.add (profile);

			var info_group = new Adw.PreferencesGroup ();
			page.add (info_group);

			if (account.account.created_at != null) {
				var join_date = new GLib.DateTime.from_iso8601 (account.account.created_at, null);
				join_date = join_date.to_timezone (new TimeZone.local ());
				info_group.add (new Adw.ActionRow () {
					title = _("Joined"),
					subtitle = join_date.format (_("%B %e, %Y")).replace (" ", ""),
					subtitle_selectable = true
				});
			}

			info_group.add (new Adw.ActionRow () {
				title = _("Role"),
				subtitle = account.role == null ? _("None") : account.role.name,
				subtitle_selectable = true
			});

			var e_mail_row = new Adw.ActionRow () {
				title = _("E-mail"),
				subtitle = account.email == null ? _("None") : account.email,
				subtitle_selectable = true
			};

			if (account.confirmed == true) {
				e_mail_row.add_suffix (new Gtk.Image.from_icon_name ("tuba-check-round-outline-symbolic") {
					css_classes = {"success"},
					valign = Gtk.Align.CENTER,
					// translators: admin dashboard, account view
					//				e-mail has been confirmed
					tooltip_text = _("Confirmed")
				});
			} else {
				e_mail_row.add_suffix (new Gtk.Image.from_icon_name ("tuba-cross-large-symbolic") {
					css_classes = {"error"},
					valign = Gtk.Align.CENTER,
					// translators: admin dashboard, account view
					//				e-mail has NOT been confirmed
					tooltip_text = _("Not Confirmed")
				});
			}

			info_group.add (e_mail_row);

			string[] ips = {};
			if (account.ips != null) {
				foreach (var account_ip in account.ips) {
					ips += account_ip.ip;
				}
			}

			info_group.add (new Adw.ActionRow () {
				title = "IPs",
				subtitle = ips.length > 0 ? string.joinv ("\n", ips) : _("None"),
				subtitle_selectable = true
			});

			var actions_row = new Adw.PreferencesGroup ();
			page.add (actions_row);

			if (!account.approved) {
				// translators: admin panel, account waiting to be approved, placeholder when they didn't include a reason
				string note = account.invite_request == null || account.invite_request == "" ? _("No Reason Given") : @"\"$(account.invite_request)\"";
				approval_row = new Adw.ActionRow () {
					activatable = false,
					// translators: admin panel, account waiting to be approved
					title = _("Awaiting Approval"),
					subtitle = note
				};

				var approve_btn = new Gtk.Button.from_icon_name ("tuba-check-round-outline-symbolic") {
					valign = Gtk.Align.CENTER,
					css_classes = { "flat", "circular", "success" },
					tooltip_text = _("Approve")
				};
				approve_btn.clicked.connect (on_approve);

				var reject_button = new Gtk.Button.from_icon_name ("tuba-cross-large-symbolic") {
					valign = Gtk.Align.CENTER,
					css_classes = { "flat", "circular", "error" },
					tooltip_text = _("Reject")
				};
				reject_button.clicked.connect (on_reject);

				approval_row.add_suffix (reject_button);
				approval_row.add_suffix (approve_btn);

				actions_row.add (approval_row);
			}

			if (account.suspended) {
				var suspended_row = new UndoRow (_("Suspended"), account_id, "unsuspend");
				suspended_row.on_error.connect (add_toast);
				suspended_row.undone.connect (mark_for_refresh);
				actions_row.add (suspended_row);
			}

			if (account.silenced) {
				var silenced_row = new UndoRow (_("Limited"), account_id, "unsilence");
				silenced_row.on_error.connect (add_toast);
				silenced_row.undone.connect (mark_for_refresh);
				actions_row.add (silenced_row);
			}

			if (account.disabled) {
				var disabled_row = new UndoRow (_("Disabled"), account_id, "enable");
				disabled_row.on_error.connect (add_toast);
				disabled_row.undone.connect (mark_for_refresh);
				actions_row.add (disabled_row);
			}
		}

		private class UndoRow : Adw.ActionRow {
			public signal void on_error (string message, uint timeout = 5);
			public signal void undone ();

			string account_id;
			string endpoint;
			Gtk.Button action_button;
			public UndoRow (string title, string account_id, string endpoint) {
				this.account_id = account_id;
				this.endpoint = endpoint;

				this.activatable = false;
				this.title = title;

				action_button = new Gtk.Button.with_label (_("Undo")) {
					valign = Gtk.Align.CENTER,
					css_classes = { "destructive-action" }
				};
				action_button.clicked.connect (on_undo);

				this.add_suffix (action_button);
			}

			private void on_undo () {
				var dlg = new Adw.AlertDialog (
					// translators: Question dialog when an admin is about to
					//				undo an action, like a suspension
					_("Undo this Action?"),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Undo"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						action_button.sensitive = false;
						new Request.POST (@"/api/v1/admin/accounts/$account_id/$endpoint")
							.with_account (accounts.active)
							.then (() => {
								this.visible = false;
								undone ();
							})
							.on_error ((code, message) => {
								action_button.sensitive = true;
								warning (@"Error while trying to undo action using $endpoint: $code $message");
								on_error (message);
							})
							.exec ();
					}
				});
			}
		}

		protected void add_toast (string content, uint timeout = 5) {
			toast_overlay.add_toast (new Adw.Toast (content) {
				timeout = timeout
			});
		}

		private void show_take_action_dialog () {
			var dlg = new Dialogs.Admin.TakeAction (account_id, account_handle, null);
			dlg.took_action.connect (on_took_action);
			dlg.present (this);
		}

		private void on_took_action () {
			mark_for_refresh ();
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

		private void on_approve () {
			var dlg = new Adw.AlertDialog (
				// translators: Question dialog when an admin is about to
				//				approve an account. The variable is an
				//				account handle
				_("Approve %s?").printf (account_handle),
				null
			);

			dlg.add_response ("no", _("Cancel"));
			dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

			dlg.add_response ("yes", _("Approve"));
			dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
			dlg.choose.begin (this, null, (obj, res) => {
				if (dlg.choose.end (res) == "yes") {
					approval_row.sensitive = false;
					new Request.POST (@"/api/v1/admin/accounts/$account_id/approve")
						.with_account (accounts.active)
						.then (() => {
							approval_row.visible = false;
							mark_for_refresh ();
						})
						.on_error ((code, message) => {
							approval_row.sensitive = true;
							warning (@"Error while trying to approve account: $code $message");
							add_toast (message);
						})
						.exec ();
				}
			});
		}

		private void on_reject () {
			var dlg = new Adw.AlertDialog (
				// translators: Question dialog when an admin is about to
				//				reject an account. The variable is an
				//				account handle
				_("Reject %s?").printf (account_handle),
				null
			);

			dlg.add_response ("no", _("Cancel"));
			dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

			dlg.add_response ("yes", _("Reject"));
			dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
			dlg.choose.begin (this, null, (obj, res) => {
				if (dlg.choose.end (res) == "yes") {
					approval_row.sensitive = false;
					new Request.POST (@"/api/v1/admin/accounts/$account_id/reject")
						.with_account (accounts.active)
						.then (() => {
							approval_row.visible = false;
							mark_for_refresh ();
						})
						.on_error ((code, message) => {
							approval_row.sensitive = true;
							warning (@"Error while trying to reject account: $code $message");
							add_toast (message);
						})
						.exec ();
				}
			});
		}
	}
}
