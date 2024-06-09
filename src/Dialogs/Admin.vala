public class Tuba.Dialogs.Admin {
	public class Place : Tuba.Place {
		[CCode (has_target = false)]
		public delegate void OpenFuncAdmin (Window window);
		public OpenFuncAdmin open_func_admin { get; set; }
	}

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/admin_dashboard.ui")]
	public class Window : Adw.Window {
		[GtkChild] public unowned Adw.NavigationSplitView split_view;
		[GtkChild] unowned Gtk.ListBox items;

		public API.AccountRole.Permissions admin_permissions { get; private set; }

		~Window () {
			debug ("Destroying Admin Dialog");
		}

		public static Place place_dash = new Place () {
			icon = "user-home-symbolic",
			title = _("Dashboard"),
			open_func_admin = (win) => {
				win.split_view.content = new Dashboard ();
			}
		};

		public static Place place_reports = new Place () {
			icon = "user-home-symbolic",
			title = _("Reports"),
			open_func_admin = (win) => {
				win.split_view.content = new ReportList () {
					admin_window = win
				};
			}
		};

		public static Place place_accounts = new Place () {
			icon = "user-home-symbolic",
			title = _("Accounts"),
			open_func_admin = (win) => {
				win.split_view.content = new AccountList () {
					admin_window = win
				};
			}
		};

		public static Place place_blocked_email_domains = new Place () {
			icon = "user-home-symbolic",
			title = _("Blocked E-mail Domains"),
			open_func_admin = (win) => {
				win.split_view.content = new BlockedEmails () {
					admin_window = win
				};
			}
		};

		public static Place place_ip_rules = new Place () {
			icon = "user-home-symbolic",
			title = _("IP Rules"),
			open_func_admin = (win) => {
				win.split_view.content = new BlockedIPs () {
					admin_window = win
				};
			}
		};

		public static Place place_federation_allow = new Place () {
			icon = "user-home-symbolic",
			title = _("Federation Allowlist"),
			open_func_admin = (win) => {
				win.split_view.content = new FederationAllowList () {
					admin_window = win
				};
			}
		};

		public static Place place_federation_deny = new Place () {
			icon = "user-home-symbolic",
			title = _("Federation Blocklist"),
			open_func_admin = (win) => {
				win.split_view.content = new FederationBlockList () {
					admin_window = win
				};
			}
		};

		construct {
			this.transient_for = app.main_window;
			this.modal = true;

			items.append (new Views.Sidebar.ItemRow (place_dash));
			if (accounts.active != null && accounts.active.admin_mode && accounts.active.role != null && accounts.active.role.permissions != null) {
				admin_permissions = new API.AccountRole.Permissions.from_string (accounts.active.role.permissions);

				if (admin_permissions.admin || admin_permissions.reports)
					items.append (new Views.Sidebar.ItemRow (place_reports));

				if (admin_permissions.admin || admin_permissions.federation) {
					items.append (new Views.Sidebar.ItemRow (place_federation_allow));
					items.append (new Views.Sidebar.ItemRow (place_federation_deny));
				}

				if (admin_permissions.admin || admin_permissions.users)
					items.append (new Views.Sidebar.ItemRow (place_accounts));

				if (admin_permissions.admin || admin_permissions.blocks) {
					items.append (new Views.Sidebar.ItemRow (place_blocked_email_domains));
					items.append (new Views.Sidebar.ItemRow (place_ip_rules));
				}
			}

			split_view.content = new Dashboard ();
		}

		[GtkCallback] void on_item_activated (Gtk.ListBoxRow _row) {
			var row = _row as Views.Sidebar.ItemRow;
			if (row == null) return;

			var place = row.place as Place;
			if (place != null && place.open_func_admin != null)
				place.open_func_admin (this);
				split_view.show_content = true;
		}
	}

	private class PaginationTimeline : Gtk.Box {
		~PaginationTimeline () {
			debug ("Destroying PaginationTimeline");
		}

		protected Gtk.ListBox content;
		public string url { get; set; default = ""; }
		public Type? accepts { get; set; default = null; }
		public bool working { get; set; default = false; }
		public signal void on_error (int code, string message);

		private string? _page_next = null;
		public string? page_next {
			get {
				return _page_next;
			}

			set {
				_page_next = value;
				next_button.sensitive = value != null;
			}
		}

		private string? _page_prev = null;
		public string? page_prev {
			get {
				return _page_prev;
			}

			set {
				_page_prev = value;
				prev_button.sensitive = value != null;
			}
		}

		private Gtk.Button prev_button;
		private Gtk.Button next_button;
		construct {
			this.orientation = Gtk.Orientation.VERTICAL;
			this.spacing = 12;

			content = new Gtk.ListBox () {
				selection_mode = Gtk.SelectionMode.NONE,
				css_classes = { "fake-content", "background" }
			};
			content.row_activated.connect (on_content_item_activated);

			var pagination_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
				homogeneous = true,
				hexpand = true,
				margin_bottom = 12
			};
			prev_button = new Gtk.Button.from_icon_name ("tuba-left-large-symbolic") {
				css_classes = {"circular", "flat"},
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				tooltip_text = ("Previous Page")
			};
			prev_button.clicked.connect (on_prev);
			pagination_buttons.append (prev_button);

			next_button = new Gtk.Button.from_icon_name ("tuba-right-large-symbolic") {
				css_classes = {"circular", "flat"},
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				tooltip_text = ("Next Page")
			};
			next_button.clicked.connect (on_next);
			pagination_buttons.append (next_button);

			this.append (new Adw.Clamp () {
				vexpand = true,
				maximum_size = 670,
				tightening_threshold = 670,
				css_classes = {"ttl-view"},
				child = content
			});
			this.append (pagination_buttons);
		}

		private void on_next () {
			first_page = false;
			url = page_next;
			request_idle ();
		}

		private void on_prev () {
			first_page = false;
			url = page_prev;
			request_idle ();
		}

		bool first_page = true;
		public void get_pages (string? header) {
			page_next = page_prev = null;
			if (header == null) {
				return;
			};

			var pages = header.split (",");
			foreach (var page in pages) {
				var sanitized = page
					.replace ("<", "")
					.replace (">", "")
					.split (";")[0];

				if ("rel=\"prev\"" in page) {
					if (!first_page) page_prev = sanitized;
				} else {
					page_next = sanitized;
				}
			}
		}

		public void request_idle () {
			GLib.Idle.add (request);
		}

		public void reset (string new_url) {
			this.url = new_url;
			first_page = true;
			request_idle ();
		}

		public virtual bool request () {
			if (accepts == null) return GLib.Source.REMOVE;
			next_button.sensitive = prev_button.sensitive = false;

			this.working = true;
			new Request.GET (url)
				.with_account (accounts.active)
				.with_ctx (this)
				.with_extra_data (Tuba.Network.ExtraData.RESPONSE_HEADERS)
				.then ((in_stream, headers) => {
					content.remove_all ();
					var parser = Network.get_parser_from_inputstream (in_stream);

					Network.parse_array (parser, node => {
						content.append (on_create_model_widget (Tuba.Helper.Entity.from_json (node, accepts)));
					});

					this.working = false;
					if (headers != null)
						get_pages (headers.get_one ("Link"));
				})
				.on_error ((code, message) => {
					on_error (code, message);
				})
				.exec ();

			return GLib.Source.REMOVE;
		}

		public virtual Gtk.Widget on_create_model_widget (Object obj) {
			var obj_widgetable = obj as BasicWidgetizable;
			if (obj_widgetable == null)
				Process.exit (0);
			try {
				Gtk.Widget widget = obj_widgetable.to_widget ();
				widget.add_css_class ("card");
				widget.add_css_class ("card-spacing");
				widget.focusable = true;

				return widget;
			} catch (Oopsie e) {
				warning (@"Error on_create_model_widget: $(e.message)");
				Process.exit (0);
			}
		}

		public virtual void on_content_item_activated (Gtk.ListBoxRow row) {}
	}

	private class BasePage : Adw.NavigationPage {
		protected Gtk.Widget page { get; set; }
		private Gtk.ScrolledWindow scroller;
		private Gtk.Spinner spinner;
		private Adw.ToastOverlay toast_overlay;
		protected Adw.HeaderBar headerbar;
		protected Adw.ToolbarView toolbar_view;
		public weak Window? admin_window { get; set; }

		~BasePage () {
			debug (@"Destroying Admin Dialog page: $title");
		}

		private bool _spinning = true;
		protected bool spinning {
			get {
				return _spinning;
			}

			set {
				_spinning = value;
				if (value) {
					scroller.child = spinner;
				} else {
					scroller.child = page;
				}
			}
		}

		construct {
			headerbar = new Adw.HeaderBar ();
			spinner = new Gtk.Spinner () {
				valign = Gtk.Align.CENTER,
				hexpand = true,
				vexpand = true,
				spinning = true,
				height_request = 32
			};

			page = new Adw.PreferencesPage () {
				hexpand = true,
				vexpand = true,
				valign = Gtk.Align.CENTER
			};

			scroller = new Gtk.ScrolledWindow () {
				vexpand = true,
				hexpand = true,
				child = spinner
			};

			toast_overlay = new Adw.ToastOverlay () {
				vexpand = true,
				hexpand = true,
				child = scroller
			};

			toolbar_view = new Adw.ToolbarView () {
				content = toast_overlay
			};
			toolbar_view.add_top_bar (headerbar);

			this.child = toolbar_view;
		}

		protected virtual void add_to_page (Adw.PreferencesGroup group) {
			var pref_page = page as Adw.PreferencesPage;
			if (pref_page != null)
				pref_page.add (group);
		}

		protected void add_toast (string content, uint timeout = 5) {
			toast_overlay.add_toast (new Adw.Toast (content) {
				timeout = timeout
			});
		}
	}

	private class Dashboard : BasePage {
		private Adw.PreferencesGroup? stats_group = null;
		const string[] KEYS = {"new_users", "active_users", "interactions", "opened_reports", "resolved_reports"};
		private string[] titles;
		private int requests = 0;

		construct {
			this.title = _("Dashboard");

			// translators: title in admin dashboard stats
			titles = {_("New Users"), _("Active Users"), _("Interactions"), _("Reports Opened"), _("Reports Resolved")};
			populate_stats ();

			// translators: group title in admin dashboard window
			do_dimension_request ("sources", _("Sign-up Sources"), 8);
			// translators: group title in admin dashboard window
			do_dimension_request ("languages", _("Top Active Languages"), 8);
			// translators: group title in admin dashboard window
			do_dimension_request ("servers", _("Top Active Servers"), 8);
			// translators: group title in admin dashboard window
			do_dimension_request ("software_versions", _("Software "), 4);
			// translators: group title in admin dashboard window
			do_dimension_request ("space_usage", _("Space Usage"), 4);
		}

		private void add_stat (Adw.ActionRow row) {
			stats_group.visible = true;
			stats_group.add (row);
		}

		private void update_requests (int change) {
			this.requests += change;
			this.spinning = this.requests > 0;
		}

		private Adw.PreferencesGroup create_group (string title) {
			var group = new Adw.PreferencesGroup () {
				title = title,
				visible = false
			};
			this.add_to_page (group);

			return group;
		}

		private void populate_stats (int i = 0) {
			if (i >= KEYS.length) return;

			if (stats_group == null) {
				stats_group = create_group (_("Stats"));
			}

			var next_i = i + 1;
			populate_stat (KEYS[i], titles[i], next_i);
		}

		private void populate_stat (string key, string title, int next_i) {
			update_requests (1);
			new Request.POST ("/api/v1/admin/measures")
				.with_account (accounts.active)
				.body_json (Dialogs.Admin.get_dimensions_body (key))
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					Network.parse_array (parser, node => {
						if (node != null) {
							var dimension = API.Admin.Dimension.from (node);
							if (dimension.key == key && dimension.total != null) {
								add_stat (
									new Adw.ActionRow () {
										title = title,
										subtitle = dimension.total,
										use_markup = false,
										subtitle_selectable = true
									}
								);

								if (next_i > -1) {
									populate_stats (next_i);
								}
							}
						}
					});

					update_requests (-1);
				})
				.on_error ((code, message) => {
					add_toast (message);
					update_requests (-1);
				})
				.exec ();
		}

		private void do_dimension_request (string key, string title, int limit) {
			update_requests (1);
			var group = create_group (title);
			new Request.POST ("/api/v1/admin/dimensions")
				.with_account (accounts.active)
				.body_json (Dialogs.Admin.get_dimensions_body (key, limit))
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					Network.parse_array (parser, node => {
						if (node != null) {
							var dimension = API.Admin.Dimension.from (node);
							if (dimension.key == key && dimension.data != null && dimension.data.size > 0) {
								foreach (var entry in dimension.data) {
									group.add (
										new Adw.ActionRow () {
											title = entry.human_key,
											subtitle = entry.human_value != null ? entry.human_value : entry.value,
											use_markup = false,
											subtitle_selectable = true
										}
									);
									group.visible = true;
								}
							}
						}
					});
					update_requests (-1);
				})
				.on_error ((code, message) => {
					add_toast (message);
					update_requests (-1);
				})
				.exec ();
		}
	}

	private class BlockedEmails : BasePage {
		public class EmailDomainTimeline : PaginationTimeline {
			~EmailDomainTimeline () {
				debug ("Destroying EmailDomainTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as Widgets.Admin.EmailDomainBlock;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (Widgets.Admin.EmailDomainBlock widget, string domain_block_id) {
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				unblock an e-mail address block. The variable
					//				is a string e-mail address
					_("Are you sure you want to unblock %s?").printf (widget.title),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Unblock"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						widget.sensitive = false;
						new Request.DELETE (@"/api/v1/admin/email_domain_blocks/$domain_block_id")
							.with_account (accounts.active)
							.then (() => {
								widget.sensitive = true;
								request_idle ();
							})
							.on_error ((code, message) => {
								widget.sensitive = true;
								on_error (code, message);
							})
							.exec ();
					}
				});
			}
		}

		Gtk.Entry child_entry;
		Gtk.Button add_button;
		EmailDomainTimeline pagination_timeline;
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

			pagination_timeline = new EmailDomainTimeline () {
				url = "/api/v1/admin/email_domain_blocks",
				accepts = typeof (API.Admin.EmailDomainBlock)
			};
			pagination_timeline.on_error.connect (on_error);
			pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
			this.page = pagination_timeline;

			pagination_timeline.request_idle ();
		}

		void new_item_cb () {
			on_action_bar_activate (child_entry.buffer);
		}

		void on_entry_changed () {
			add_button.sensitive = child_entry.text.length > 0;
		}

		void on_action_bar_activate (Gtk.EntryBuffer buffer) {
			if (buffer.length > 0) {
				string domain = buffer.text;
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				block an e-mail domain. The variable is a
					//				string.
					_("Are you sure you want to block %s?").printf (domain),

					// tranlsators: Question dialog description when an admin is about to
					//				block an e-mail domain. The variable is a string.
					//				you can find this string translated on https://github.com/mastodon/mastodon/tree/main/app/javascript/mastodon/locales
					_("This can be the domain name that shows up in the e-mail address or the MX record it uses. They will be checked upon sign-up.")
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Block"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this.admin_window, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						new Request.POST ("/api/v1/admin/email_domain_blocks")
							.with_account (accounts.active)
							.with_form_data ("domain", domain)
							.then (() => {
								pagination_timeline.request_idle ();
							})
							.on_error ((code, message) => {
								warning (@"Error trying to block e-mail domain $domain: $message $code");
								on_error (code, message);
							})
							.exec ();
					}
				});
			}
			buffer.set_text ("".data);
		}

		private void on_error (int code, string message) {
			this.add_toast (@"$message $code");
		}
	}

	private class BlockedIPs : BasePage {
		public class BlockedIPsTimeline : PaginationTimeline {
			~BlockedIPsTimeline () {
				debug ("Destroying BlockedIPsTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as Widgets.Admin.IPBlock;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (Widgets.Admin.IPBlock widget, string ip_block_id) {
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				unblock an IP address. The variable
					//				is a string IP address
					_("Are you sure you want to unblock %s?").printf (widget.title),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Unblock"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						widget.sensitive = false;
						new Request.DELETE (@"/api/v1/admin/ip_blocks/$ip_block_id")
							.with_account (accounts.active)
							.then (() => {
								widget.sensitive = true;
								request_idle ();
							})
							.on_error ((code, message) => {
								widget.sensitive = true;
								on_error (code, message);
							})
							.exec ();
					}
				});
			}
		}

		public class AddIPBlockDialog : Adw.Dialog {
			~AddIPBlockDialog () {
				debug ("Destroying AddIPBlockDialog");
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
			Adw.PreferencesPage page;
			Adw.EntryRow ip_row;
			Adw.ComboRow exp_row;
			GLib.ListStore exp_model;
			Gtk.CheckButton rule_no_access;
			Gtk.CheckButton rule_signup_block;
			Gtk.CheckButton rule_signup_approve;
			Adw.EntryRow comment_row;
			Adw.ToastOverlay toast_overlay;
			construct {
				this.title = _("Add IP Block");
				this.content_width = 460;
				this.content_height = 502;
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
				toolbarview.add_top_bar (headerbar);
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

				this.child = toolbarview;
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
						toast_overlay.add_toast (new Adw.Toast (message) {
							timeout = 10
						});
					})
					.exec ();
			}

			private void exp_signal (GLib.Object item) {
				((Gtk.ListItem) item).child = new Gtk.Label (((ExpirationObject)((Gtk.ListItem) item).item).expiration.to_string ());
			}
		}

		BlockedIPsTimeline pagination_timeline;
		construct {
			// translators: Admin Dialog page title,
			//				this is about blocking
			//				IP Addresses
			this.title = _("IP Rules");

			var add_ip_block_button = new Gtk.Button.from_icon_name ("tuba-plus-large-symbolic") {
				tooltip_text = _("Add IP Block"),
				css_classes = {"flat"}
			};
			add_ip_block_button.clicked.connect (open_add_ip_block_dialog);
			headerbar.pack_end (add_ip_block_button);

			pagination_timeline = new BlockedIPsTimeline () {
				url = "/api/v1/admin/ip_blocks",
				accepts = typeof (API.Admin.IPBlock)
			};
			pagination_timeline.on_error.connect (on_error);
			pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
			this.page = pagination_timeline;

			refresh ();
		}

		private void open_add_ip_block_dialog () {
			if (this.admin_window == null) return;
			var add_ip_block_dialog = new AddIPBlockDialog ();
			add_ip_block_dialog.added.connect (refresh);
			add_ip_block_dialog.present (this.admin_window);
		}

		private void refresh () {
			pagination_timeline.request_idle ();
		}

		private void on_error (int code, string message) {
			this.add_toast (@"$message $code");
		}
	}

	private class FederationAllowList : BasePage {
		public class DomainAllowTimeline : PaginationTimeline {
			~DomainAllowTimeline () {
				debug ("Destroying DomainAllowTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as Widgets.Admin.DomainAllow;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (Widgets.Admin.DomainAllow widget, string domain_allow_id) {
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				delete a domain from the federation allowlist.
					//				You can replace 'federate' with 'communicate' if
					//				it's hard to translate.
					//				The variable is a string domain name
					_("Are you sure you want to no longer federate with %s?").printf (widget.title),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Remove"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						widget.sensitive = false;
						new Request.DELETE (@"/api/v1/admin/domain_allows/$domain_allow_id")
							.with_account (accounts.active)
							.then (() => {
								widget.sensitive = true;
								request_idle ();
							})
							.on_error ((code, message) => {
								widget.sensitive = true;
								on_error (code, message);
							})
							.exec ();
					}
				});
			}
		}

		Gtk.Entry child_entry;
		Gtk.Button add_button;
		DomainAllowTimeline pagination_timeline;
		construct {
			// translators: Admin Dialog page title
			this.title = _("Federation Allowlist");

			var add_action_bar = new Gtk.ActionBar () {
				css_classes = { "ttl-box-no-shadow" }
			};

			child_entry = new Gtk.Entry () {
				input_purpose = Gtk.InputPurpose.URL,
				// translators: Admin Dialog entry placeholder text,
				//				this is about allowing federation
				//				with other instances
				placeholder_text = _("Allow federation with an instance")
			};
			var child_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
			add_button = new Gtk.Button.with_label (_("Allow")) {
				sensitive = false
			};
			add_button.clicked.connect (new_item_cb);
			child_entry.activate.connect (new_item_cb);
			child_entry.notify["text"].connect (on_entry_changed);

			child_box.append (child_entry);
			child_box.append (add_button);

			add_action_bar.set_center_widget (child_box);
			toolbar_view.add_top_bar (add_action_bar);

			pagination_timeline = new DomainAllowTimeline () {
				url = "/api/v1/admin/domain_allows",
				accepts = typeof (API.Admin.DomainAllow)
			};
			pagination_timeline.on_error.connect (on_error);
			pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
			this.page = pagination_timeline;

			pagination_timeline.request_idle ();
		}

		void new_item_cb () {
			on_action_bar_activate (child_entry.buffer);
		}

		void on_entry_changed () {
			add_button.sensitive = child_entry.text.length > 0;
		}

		void on_action_bar_activate (Gtk.EntryBuffer buffer) {
			if (buffer.length > 0) {
				string domain = buffer.text;
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				allow federation with an instance. The variable is a
					//				string.
					_("Are you sure you want to allow federation with %s?").printf (domain),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Allow"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this.admin_window, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						new Request.POST ("/api/v1/admin/domain_allows")
							.with_account (accounts.active)
							.with_form_data ("domain", domain)
							.then (() => {
								pagination_timeline.request_idle ();
							})
							.on_error ((code, message) => {
								warning (@"Error trying to allow federation with $domain: $message $code");
								on_error (code, message);
							})
							.exec ();
					}
				});
			}
			buffer.set_text ("".data);
		}

		private void on_error (int code, string message) {
			this.add_toast (@"$message $code");
		}
	}

	private class FederationBlockList : BasePage {
		public class FederationBlockTimeline : PaginationTimeline {
			~FederationBlockTimeline () {
				debug ("Destroying FederationBlockTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as Widgets.Admin.DomainBlock;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (Widgets.Admin.DomainBlock widget, string federation_block_id) {
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				delete a federation block. The variable is
					//				a string domain name
					_("Are you sure you want to unblock %s?").printf (widget.title),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Unblock"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.DESTRUCTIVE);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						widget.sensitive = false;
						new Request.DELETE (@"/api/v1/admin/domain_blocks/$federation_block_id")
							.with_account (accounts.active)
							.then (() => {
								widget.sensitive = true;
								request_idle ();
							})
							.on_error ((code, message) => {
								widget.sensitive = true;
								on_error (code, message);
							})
							.exec ();
					}
				});
			}
		}

		public class AddFederationBlockDialog : Adw.Dialog {
			~AddFederationBlockDialog () {
				debug ("Destroying AddFederationBlockDialog");
			}

			class SeverityObject : Object {
				public API.Admin.DomainBlock.Severity severity { get; set; }

				public SeverityObject (API.Admin.DomainBlock.Severity sev) {
					this.severity = sev;
				}
			}

			public signal void added ();

			Gtk.Button save_button;
			Adw.PreferencesPage page;
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
			Adw.ToastOverlay toast_overlay;
			construct {
				this.title = _("Add Federation Block");
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
				toolbarview.add_top_bar (headerbar);
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
				this.child = toolbarview;
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
						toast_overlay.add_toast (new Adw.Toast (message) {
							timeout = 10
						});
					})
					.exec ();
			}

			private void sev_signal (GLib.Object item) {
				((Gtk.ListItem) item).child = new Gtk.Label (((SeverityObject)((Gtk.ListItem) item).item).severity.to_string ());
			}
		}

		FederationBlockTimeline pagination_timeline;
		construct {
			// translators: Admin Dialog page title,
			//				this is about federation blocking
			this.title = _("Federation Blocklist");

			var add_ip_block_button = new Gtk.Button.from_icon_name ("tuba-plus-large-symbolic") {
				tooltip_text = _("Add Federation Block"),
				css_classes = {"flat"}
			};
			add_ip_block_button.clicked.connect (open_add_federation_block_dialog);
			headerbar.pack_end (add_ip_block_button);

			pagination_timeline = new FederationBlockTimeline () {
				url = "/api/v1/admin/domain_blocks",
				accepts = typeof (API.Admin.DomainBlock)
			};
			pagination_timeline.on_error.connect (on_error);
			pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
			this.page = pagination_timeline;

			refresh ();
		}

		private void open_add_federation_block_dialog () {
			if (this.admin_window == null) return;
			var add_federation_block_dialog = new AddFederationBlockDialog ();
			add_federation_block_dialog.added.connect (refresh);
			add_federation_block_dialog.present (this.admin_window);
		}

		private void refresh () {
			pagination_timeline.request_idle ();
		}

		private void on_error (int code, string message) {
			this.add_toast (@"$message $code");
		}
	}

	private class ReportList : BasePage {
		public class ReportDialog : Adw.Dialog {
			public signal void refresh ();

			Adw.PreferencesGroup profile_group;
			Adw.PreferencesPage page;
			Adw.ToastOverlay toast_overlay;
			Gtk.Button take_action_button;
			Gtk.Button resolve_button;
			Adw.HeaderBar headerbar;
			construct {
				this.title = _("Report");
				this.content_width = 460;
				this.content_height = 560;
				this.can_close = false;

				page = new Adw.PreferencesPage ();
				toast_overlay = new Adw.ToastOverlay () {
					vexpand = true,
					hexpand = true,
					child = page
				};

				var toolbarview = new Adw.ToolbarView () {
					content = toast_overlay
				};

				headerbar = new Adw.HeaderBar ();
				toolbarview.add_top_bar (headerbar);

				profile_group = new Adw.PreferencesGroup ();
				page.add (profile_group);
				this.child = toolbarview;

				this.closed.connect (on_close);
			}

			protected void add_toast (string content, uint timeout = 5) {
				toast_overlay.add_toast (new Adw.Toast (content) {
					timeout = 5
				});
			}

			private void on_resolve () {
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				mark a report as resolved
					_("Are you sure you want to mark this report as resolved?"),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Resolve"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.SUGGESTED);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						resolve_button.sensitive = false;
						new Request.POST (@"/api/v1/admin/reports/$report_id/resolve")
							.with_account (accounts.active)
							.then (() => {
								should_refresh = true;
								on_close ();
							})
							.on_error ((code, message) => {
								warning (@"Error trying to resolve report $report_id: $message $code");
								add_toast (@"$message $code");
								resolve_button.sensitive = true;
							})
							.exec ();
					}
				});
			}

			private void on_reopen () {
				var dlg = new Adw.AlertDialog (
					// tranlsators: Question dialog when an admin is about to
					//				reopen a report
					_("Are you sure you want to reopen this report?"),
					null
				);

				dlg.add_response ("no", _("Cancel"));
				dlg.set_response_appearance ("no", Adw.ResponseAppearance.DEFAULT);

				dlg.add_response ("yes", _("Reopen"));
				dlg.set_response_appearance ("yes", Adw.ResponseAppearance.SUGGESTED);
				dlg.choose.begin (this, null, (obj, res) => {
					if (dlg.choose.end (res) == "yes") {
						resolve_button.sensitive = false;
						new Request.POST (@"/api/v1/admin/reports/$report_id/reopen")
							.with_account (accounts.active)
							.then (() => {
								should_refresh = true;
								on_close ();
							})
							.on_error ((code, message) => {
								warning (@"Error trying to reopen report $report_id: $message $code");
								add_toast (@"$message $code");
								resolve_button.sensitive = true;
							})
							.exec ();
					}
				});
			}

			~ReportDialog () {
				debug ("Destroying ReportDialog");
				rules_buttons.clear ();
			}

			class AssignedToRow : Adw.ActionRow {
				public signal void assignment_changed (string new_handle);
				public signal void on_error (string error_message);
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
							var parser = Network.get_parser_from_inputstream (in_stream);
							var node = network.parse_node (parser);
							update_account (API.Admin.Report.from (node).assigned_account);
							assign_button.sensitive = true;
						})
						.on_error ((code, message) => {
							warning (@"Error trying to re-assign $report_id: $message $code");
							on_error (@"$message $code");
							assign_button.sensitive = true;
						})
						.exec ();
				}
			}

			private void on_assign_row_error (string content) {
				add_toast (content);
			}

			string report_id;
			string account_id;
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
			public ReportDialog (API.Admin.Report report) {
				report_id = report.id;
				account_id = report.target_account.account.id;
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
					var row = new AssignedToRow (report.id, report.assigned_account);
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
						status.formal.spoiler_text = null;
						Widgets.Status widget = (Widgets.Status) status.to_widget ();
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
				var dlg = new TakeActionDialog (account_id, report_id);
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

			class TakeActionDialog : Adw.Dialog {
				public signal void took_action ();

				Adw.PreferencesPage page;
				Adw.ToastOverlay toast_overlay;
				Adw.HeaderBar headerbar;
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

					page = new Adw.PreferencesPage ();
					toast_overlay = new Adw.ToastOverlay () {
						vexpand = true,
						hexpand = true,
						child = page
					};

					var toolbarview = new Adw.ToolbarView () {
						content = toast_overlay
					};

					var cancel_button = new Gtk.Button.with_label (_("Cancel"));
					cancel_button.clicked.connect (on_cancel);

					take_action_button = new Gtk.Button.with_label (_("Submit")) {
						css_classes = {"destructive-action"}
					};
					take_action_button.clicked.connect (on_take_action);

					headerbar = new Adw.HeaderBar () {
						show_end_title_buttons = false,
						show_start_title_buttons = false
					};

					headerbar.pack_start (cancel_button);
					headerbar.pack_end (take_action_button);
					toolbarview.add_top_bar (headerbar);

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
						subtitle = _("Use this to send a warning to the user, without triggering any other action"),
						activatable_widget = action_warning
					};
					action_row.add_prefix (action_warning);
					action_group.add (action_row);

					action_row = new Adw.ActionRow () {
						title = _("Freeze"),
						subtitle = _("Prevent the user from using their account, but do not delete or hide their contents"),
						activatable_widget = action_freeze
					};
					action_row.add_prefix (action_freeze);
					action_group.add (action_row);

					action_row = new Adw.ActionRow () {
						title = _("Sensitive"),
						subtitle = _("Force all this user's media attachments to be flagged as sensitive"),
						activatable_widget = action_sensitive
					};
					action_row.add_prefix (action_sensitive);
					action_group.add (action_row);

					action_row = new Adw.ActionRow () {
						title = _("Limit"),
						subtitle = _("Prevent the user from being able to post with public visibility, hide their posts and notifications from people not following them. Closes all reports against this account"),
						activatable_widget = action_limit
					};
					action_row.add_prefix (action_limit);
					action_group.add (action_row);

					action_row = new Adw.ActionRow () {
						title = _("Suspend"),
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
						title = _("Notify the user per e-mail"),
						subtitle = _("The user will receive an explanation of what happened with their account"),
						activatable_widget = send_email
					};
					action_row.add_prefix (send_email);
					action_group.add (action_row);

					page.add (action_group);
					this.child = toolbarview;
				}

				string account_id;
				string? report_id = null;
				public TakeActionDialog (string account_id, string? report_id = null) {
					this.account_id = account_id;
					this.report_id = report_id;
				}

				protected void add_toast (string content, uint timeout = 5) {
					toast_overlay.add_toast (new Adw.Toast (content) {
						timeout = 5
					});
				}

				private void on_cancel () {
					this.force_close ();
				}

				private void on_take_action () {
					var dlg = new Adw.AlertDialog (
						// tranlsators: Question dialog when an admin is about to
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
									add_toast (@"$message $code");
								});

							if (report_id != null) req.with_form_data ("report_id", report_id);

							req.exec ();
						}
					});
				}
			}
		}

		public class ReportTimeline : PaginationTimeline {
			~ReportTimeline () {
				debug ("Destroying ReportTimeline");
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

		ReportTimeline pagination_timeline;
		Gtk.ToggleButton resolved_button;
		construct {
			// translators: Admin Dialog page title
			this.title = _("Reports");

			resolved_button = new Gtk.ToggleButton () {
				// translators: admin dashboard, reports timeline, headerbar button tooltip text
				tooltip_text = _("Show Resolved Reports"),
				css_classes = {"flat"},
				icon_name = "tuba-check-round-outline-symbolic"
			};
			resolved_button.toggled.connect (on_resolved_toggled);
			headerbar.pack_end (resolved_button);

			pagination_timeline = new ReportTimeline () {
				url = "/api/v1/admin/reports",
				accepts = typeof (API.Admin.Report)
			};
			pagination_timeline.on_open_report_dialog.connect (open_report_dialog);
			pagination_timeline.on_error.connect (on_error);
			pagination_timeline.bind_property ("working", this, "spinning", GLib.BindingFlags.SYNC_CREATE);
			pagination_timeline.bind_property ("working", resolved_button, "sensitive", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
			this.page = pagination_timeline;

			refresh ();
		}

		private void on_resolved_toggled () {
			pagination_timeline.reset (resolved_button.active ? "/api/v1/admin/reports?resolved=true" : "/api/v1/admin/reports");
		}

		private void on_error (int code, string message) {
			pagination_timeline.working = false;
			this.add_toast (@"$message $code");
		}

		private void refresh () {
			pagination_timeline.request_idle ();
		}

		private void open_report_dialog (API.Admin.Report report) {
			var report_dialog = new ReportDialog (report);
			report_dialog.refresh.connect (refresh);
			report_dialog.present (this.admin_window);
		}
	}

	private class AccountList : BasePage {
		public class AccountListAccount : API.Admin.Account, BasicWidgetizable {
			public override Gtk.Widget to_widget () {
				return new AccountRow (this);
			}
		}

		public class AccountRow : Adw.ActionRow {
			public signal void account_opened (AccountListAccount account_obj);

			~AccountRow () {
				debug ("Destroying AccountRow");
			}

			AccountListAccount account_obj;
			public AccountRow (AccountListAccount account) {
				account_obj = account;
				string ip = account.ip == null ? "" : @"$(account.ip)\n";
				string email = account.email == null ? "" : account.email;

				this.overflow = Gtk.Overflow.HIDDEN;
				this.subtitle_lines = 0;
				this.title = account.account.display_name;
				this.subtitle = @"$(account.account.full_handle)\n$(ip)$(email)";
				this.activated.connect (on_activate);
				this.activatable = true;

				this.add_prefix (new Widgets.Avatar () {
					account = account.account,
					size = 48
				});

				string status = _("No Limits");
				if (account.suspended) {
					status = _("Suspended");
				} else if (account.silenced) {
					status = _("Limited");
				} else if (account.disabled) {
					status = _("Disabled");
				} else if (!account.approved) {
					// translators: admin panel, account waiting to be approved
					status = _("Waiting Approval");
				}

				this.add_suffix (new Gtk.Label (status) {
					xalign = 1.0f,
					wrap = true,
					wrap_mode = Pango.WrapMode.WORD_CHAR,
					hexpand = true
				});
			}

			public void on_activate () {
				account_opened (account_obj);
			}
		}

		public class AccountTimeline : PaginationTimeline {
			~AccountTimeline () {
				debug ("Destroying AccountTimeline");
			}

			public signal void on_open_account (AccountListAccount account);
			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as AccountRow;
				if (action_row != null) {
					action_row.account_opened.connect (on_account_opened);
				}

				return widget;
			}

			private void on_account_opened (AccountListAccount account) {
				on_open_account (account);
			}
		}

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
		AccountTimeline pagination_timeline;
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
			var breakpoint = new Adw.Breakpoint (condition);
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

			pagination_timeline = new AccountTimeline () {
				url = "/api/v1/admin/accounts",
				accepts = typeof (AccountListAccount)
			};
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

		private void on_error (int code, string message) {
			this.add_toast (@"$message $code");
		}

		private void refresh () {
			pagination_timeline.request_idle ();
		}

		private void dropdown_signal (GLib.Object item) {
			((Gtk.ListItem) item).child = new Gtk.Label (((DropDownStringEntry)((Gtk.ListItem) item).item).title) {
				ellipsize = Pango.EllipsizeMode.END
			};
		}

		private void show_account_dialog (AccountListAccount account) {
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
			public AccountDialog (AccountListAccount account) {
				account_id = account.account.id;
				account_handle = account.account.full_handle;
				this.title = account.account.full_handle;

				var profile_group = new Adw.PreferencesGroup ();
				page.add (profile_group);

				try {
					Widgets.Account profile = (Widgets.Account) account.account.to_widget ();
					profile.overflow = Gtk.Overflow.HIDDEN;
					profile.disable_profile_open = true;
					profile.add_css_class ("card");
					profile_group.add (profile);
				} catch {}

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

				string confirmation_text = account.confirmed == true
					// translators: admin dashboard, account view
					//				e-mail has been confirmed
					? _("Confirmed")
					// translators: admin dashboard, account view
					//				e-mail has NOT been confirmed
					: _("Not Confirmed");

				info_group.add (new Adw.ActionRow () {
					// translators: admin dashboard, account view,
					//				e-mail confirmation status
					title = _("E-mail Status"),
					subtitle = confirmation_text,
					subtitle_selectable = true
				});

				info_group.add (new Adw.ActionRow () {
					title = _("E-mail"),
					subtitle = account.email == null ? _("None") : account.email,
					subtitle_selectable = true
				});

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
						// tranlsators: Question dialog when an admin is about to
						//				undo an action, like a suspension
						_("Are you sure you want to undo this action?"),
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
				var dlg = new ReportList.ReportDialog.TakeActionDialog (account_id, null);
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
					// tranlsators: Question dialog when an admin is about to
					//				approve an account. The variable is an
					//				account handle
					_("Are you sure you want to approve %s?").printf (account_handle),
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
					// tranlsators: Question dialog when an admin is about to
					//				reject an account. The variable is an
					//				account handle
					_("Are you sure you want to reject %s?").printf (account_handle),
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

	private static Json.Builder get_dimensions_body (string key, int limit = 0) {
		var now = new GLib.DateTime.now_local ();
		var end = new GLib.DateTime.now_local ();
		now = now.add_days (-29);

		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("start_at");
		builder.add_string_value (now.format ("%F"));

		builder.set_member_name ("keys");
		builder.begin_array ();
		builder.add_string_value (key);
		builder.end_array ();

		if (limit > 0) {
			builder.set_member_name ("limit");
			builder.add_int_value (limit);
		}

		builder.set_member_name ("end_at");
		builder.add_string_value (end.format ("%F"));

		builder.end_object ();

		return builder;
	}
}
