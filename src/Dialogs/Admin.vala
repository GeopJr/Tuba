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
			var add_ip_block_dialog = new Dialogs.TmpAdmin.AddIPBlock ();
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
			var add_federation_block_dialog = new Dialogs.TmpAdmin.AddFederationBlock ();
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
			var report_dialog = new Dialogs.TmpAdmin.Report (report);
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
				var dlg = new Dialogs.TmpAdmin.TakeAction (account_id, null);
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
