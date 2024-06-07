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
		public interface BasicWidgetizable : GLib.Object {
			public virtual Gtk.Widget to_widget () throws Oopsie {
				throw new Tuba.Oopsie.INTERNAL ("BasicWidgetizable didn't provide a Widget!");
			}
		}

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
		public class EmailDomainBlockWidget : Adw.ActionRow {
			public signal void removed (string domain_block_id);

			~EmailDomainBlockWidget () {
				debug ("Destroying EmailDomainBlockWidget");
			}

			string domain_block_id;
			public EmailDomainBlockWidget (EmailDomainBlock domain_block) {
				domain_block_id = domain_block.id;
				this.title = domain_block.domain;

				int total_attempts = 0;
				if (domain_block.history != null) {
					domain_block.history.foreach ((entity) => {
						total_attempts += int.parse (entity.accounts) + int.parse (entity.uses);
						return true;
					});
				}

				// translators: subtitle on email domain blocks.
				//				The variable is the number of sing up
				//				attempts using said email domain.
				this.subtitle = _("%d Sign-up Attempts").printf (total_attempts);

				var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
					css_classes = { "circular", "flat", "error" },
					tooltip_text = _("Delete"),
					valign = Gtk.Align.CENTER
				};
				delete_button.clicked.connect (on_remove);
				this.add_suffix (delete_button);
			}

			public void on_remove () {
				removed (domain_block_id);
			}
		}

		public class EmailDomainBlock : Entity, PaginationTimeline.BasicWidgetizable {
			public class History : Entity {
				public string accounts { get; set; }
				public string uses { get; set; }
			}

			public string id { get; set; }
			public string domain { get; set; }
			public Gee.ArrayList<History>? history { get; set; default=null; }

			public override Type deserialize_array_type (string prop) {
				switch (prop) {
					case "history":
						return typeof (History);
				}

				return base.deserialize_array_type (prop);
			}

			public override Gtk.Widget to_widget () {
				return new EmailDomainBlockWidget (this);
			}
		}

		public class EmailDomainTimeline : PaginationTimeline {
			~EmailDomainTimeline () {
				debug ("Destroying EmailDomainTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as EmailDomainBlockWidget;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (EmailDomainBlockWidget widget, string domain_block_id) {
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
				accepts = typeof (EmailDomainBlock)
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
					_("Are you sure you want to block %s").printf (domain),

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
		public class IPBlockWidget : Adw.ActionRow {
			public signal void removed (string ip_block_id);

			~IPBlockWidget () {
				debug ("Destroying IPBlockWidget");
			}

			string ip_block_id;
			public IPBlockWidget (IPBlock ip_block) {
				ip_block_id = ip_block.id;
				this.title = ip_block.ip;

				string sub = IPBlock.Severity.from_string (ip_block.severity).to_string ();
				if (ip_block.comment != "") sub += @" · $(ip_block.comment)";
				this.subtitle = sub;

				var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
					css_classes = { "circular", "flat", "error" },
					tooltip_text = _("Delete"),
					valign = Gtk.Align.CENTER
				};
				delete_button.clicked.connect (on_remove);
				this.add_suffix (delete_button);
			}

			public void on_remove () {
				removed (ip_block_id);
			}
		}

		public class IPBlock : Entity, PaginationTimeline.BasicWidgetizable {
			public enum Severity {
				NO_ACCESS,
				SIGN_UP_BLOCK,
				SIGN_UP_REQUIRES_APPROVAL;

				public string to_string () {
					switch (this) {
						// translators: Admin Dashboard, IP Block severity
						case NO_ACCESS: return _("Blocked");
						// translators: Admin Dashboard, IP Block severity
						case SIGN_UP_BLOCK: return _("Blocked Sign-ups");
						// translators: Admin Dashboard, IP Block severity
						case SIGN_UP_REQUIRES_APPROVAL: return _("Limited Sign-ups");
						default: assert_not_reached ();
					}
				}

				public string to_title () {
					switch (this) {
						// translators: Admin Dashboard, IP Block severity title
						case NO_ACCESS: return _("Block Access");
						// translators: Admin Dashboard, IP Block severity title
						case SIGN_UP_BLOCK: return _("Block Sign-ups");
						// translators: Admin Dashboard, IP Block severity title
						case SIGN_UP_REQUIRES_APPROVAL: return _("Limit Sign-ups");
						default: assert_not_reached ();
					}
				}

				public string to_descritpion () {
					switch (this) {
						// translators: Admin Dashboard, IP Block severity description
						case NO_ACCESS: return _("Block access to all resources");
						// translators: Admin Dashboard, IP Block severity description
						case SIGN_UP_BLOCK: return _("New sign-ups will not be possible");
						// translators: Admin Dashboard, IP Block severity description
						case SIGN_UP_REQUIRES_APPROVAL: return _("New sign-ups will require your approval");
						default: assert_not_reached ();
					}
				}

				public static Severity from_string (string severity) {
					switch (severity.down ()) {
						case "sign_up_block": return SIGN_UP_BLOCK;
						case "sign_up_requires_approval": return SIGN_UP_REQUIRES_APPROVAL;
						default: return NO_ACCESS;
					}
				}

				public string to_api_string () {
					switch (this) {
						case NO_ACCESS: return "no_access";
						case SIGN_UP_BLOCK: return "sign_up_block";
						case SIGN_UP_REQUIRES_APPROVAL: return "sign_up_requires_approval";
						default: assert_not_reached ();
					}
				}
			}

			public string id { get; set; }
			public string ip { get; set; }
			public string severity { get; set; default = "no_access"; }
			public string comment { get; set; default = ""; }

			public override Gtk.Widget to_widget () {
				return new IPBlockWidget (this);
			}
		}

		public class BlockedIPsTimeline : PaginationTimeline {
			~BlockedIPsTimeline () {
				debug ("Destroying BlockedIPsTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as IPBlockWidget;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (IPBlockWidget widget, string ip_block_id) {
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
					active = true
				};
				rule_signup_block = new Gtk.CheckButton () {
					group = rule_no_access
				};
				rule_signup_approve = new Gtk.CheckButton () {
					group = rule_no_access
				};

				var action_row = new Adw.ActionRow () {
					title = IPBlock.Severity.NO_ACCESS.to_title (),
					subtitle = IPBlock.Severity.NO_ACCESS.to_descritpion (),
					activatable_widget = rule_no_access
				};
				action_row.add_prefix (rule_no_access);
				rule_group.add (action_row);

				action_row = new Adw.ActionRow () {
					title = IPBlock.Severity.SIGN_UP_BLOCK.to_title (),
					subtitle = IPBlock.Severity.SIGN_UP_BLOCK.to_descritpion (),
					activatable_widget = rule_signup_block
				};
				action_row.add_prefix (rule_signup_block);
				rule_group.add (action_row);

				action_row = new Adw.ActionRow () {
					title = IPBlock.Severity.SIGN_UP_REQUIRES_APPROVAL.to_title (),
					subtitle = IPBlock.Severity.SIGN_UP_REQUIRES_APPROVAL.to_descritpion (),
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

				IPBlock.Severity sev = IPBlock.Severity.NO_ACCESS;
				if (rule_signup_approve.active) {
					sev = IPBlock.Severity.SIGN_UP_REQUIRES_APPROVAL;
				} else if (rule_signup_block.active) {
					sev = IPBlock.Severity.SIGN_UP_BLOCK;
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
				accepts = typeof (IPBlock)
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
		public class FederationAllowWidget : Adw.ActionRow {
			public signal void removed (string domain_allow_id);

			~FederationAllowWidget () {
				debug ("Destroying FederationAllowWidget");
			}

			string domain_allow_id;
			public FederationAllowWidget (DomainAllow domain_allow) {
				domain_allow_id = domain_allow.id;
				this.title = domain_allow.domain;

				var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
					css_classes = { "circular", "flat", "error" },
					tooltip_text = _("Delete"),
					valign = Gtk.Align.CENTER
				};
				delete_button.clicked.connect (on_remove);
				this.add_suffix (delete_button);
			}

			public void on_remove () {
				removed (domain_allow_id);
			}
		}

		public class DomainAllow : Entity, PaginationTimeline.BasicWidgetizable {
			public string id { get; set; }
			public string domain { get; set; }

			public override Gtk.Widget to_widget () {
				return new FederationAllowWidget (this);
			}
		}

		public class DomainAllowTimeline : PaginationTimeline {
			~DomainAllowTimeline () {
				debug ("Destroying DomainAllowTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as FederationAllowWidget;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (FederationAllowWidget widget, string domain_allow_id) {
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
				accepts = typeof (DomainAllow)
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
					_("Are you sure you want to allow federation with %s").printf (domain),
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
		public class FederationBlockWidget : Adw.ExpanderRow {
			public signal void removed (string federation_block_id);

			~FederationBlockWidget () {
				debug ("Destroying FederationBlockWidget");
			}

			string federation_block_id;
			public FederationBlockWidget (FederationBlock federation_block) {
				federation_block_id = federation_block.id;
				this.overflow = Gtk.Overflow.HIDDEN;
				this.title = federation_block.domain;
				this.subtitle = FederationBlock.Severity.from_string (federation_block.severity).to_string ();
				this.add_row (
					new Gtk.Label (
						"<b>%s</b>: %s".printf (
							_("Private Comment"),
							federation_block.private_comment == null || federation_block.private_comment == "" ? _("None") : federation_block.private_comment
						)
					) {
						wrap = true,
						xalign = 0.0f,
						wrap_mode = Pango.WrapMode.WORD_CHAR,
						use_markup = true,
						margin_bottom = 8,
						margin_top = 8,
						margin_start = 8,
						margin_end = 8,
					}
				);
				this.add_row (
					new Gtk.Label (
						"<b>%s</b>: %s".printf (
							_("Public Comment"),
							federation_block.public_comment == null || federation_block.public_comment == "" ? _("None") : federation_block.public_comment
						)
					) {
						wrap = true,
						xalign = 0.0f,
						wrap_mode = Pango.WrapMode.WORD_CHAR,
						use_markup = true,
						margin_bottom = 8,
						margin_top = 8,
						margin_start = 8,
						margin_end = 8,
					}
				);

				string[] rules = {};
				if (federation_block.reject_media) rules += _("Reject Media Files");
				if (federation_block.reject_reports) rules += _("Reject Reports");
				if (federation_block.obfuscate) rules += _("Obfuscate Domain Name");

				if (rules.length > 0) {
					this.add_row (
						new Gtk.Label (
							"<b>%s</b>".printf (string.joinv ("·", rules))
						) {
							wrap = true,
							xalign = 0.0f,
							wrap_mode = Pango.WrapMode.WORD_CHAR,
							use_markup = true,
							margin_bottom = 12,
							margin_top = 12,
							margin_start = 12,
							margin_end = 12,
						}
					);
				}


				var delete_button = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
					css_classes = { "circular", "flat", "error" },
					tooltip_text = _("Delete"),
					valign = Gtk.Align.CENTER
				};
				delete_button.clicked.connect (on_remove);
				this.add_suffix (delete_button);
			}

			public void on_remove () {
				removed (federation_block_id);
			}
		}

		public class FederationBlock : Entity, PaginationTimeline.BasicWidgetizable {
			public enum Severity {
				NOOP,
				SILENCE,
				SUSPEND;

				public string to_string () {
					switch (this) {
						// translators: Admin Dashboard, Federation Block severity
						case NOOP: return _("None");
						// translators: Admin Dashboard, Federation Block severity
						case SILENCE: return _("Limit");
						// translators: Admin Dashboard, Federation Block severity
						case SUSPEND: return _("Suspend");
						default: assert_not_reached ();
					}
				}

				public static Severity from_string (string severity) {
					switch (severity.down ()) {
						case "silence": return SILENCE;
						case "suspend": return SUSPEND;
						default: return NOOP;
					}
				}

				public string to_api_string () {
					switch (this) {
						case NOOP: return "noop";
						case SILENCE: return "silence";
						case SUSPEND: return "suspend";
						default: assert_not_reached ();
					}
				}
			}

			public string id { get; set; }
			public string domain { get; set; }
			public string severity { get; set; default = "noop"; }
			public string private_comment { get; set; default = ""; }
			public string public_comment { get; set; default = ""; }
			public bool obfuscate { get; set; default = false; }
			public bool reject_media { get; set; default = false; }
			public bool reject_reports { get; set; default = false; }

			public override Gtk.Widget to_widget () {
				return new FederationBlockWidget (this);
			}
		}

		public class FederationBlockTimeline : PaginationTimeline {
			~FederationBlockTimeline () {
				debug ("Destroying FederationBlockTimeline");
			}

			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as FederationBlockWidget;
				if (action_row != null) {
					action_row.removed.connect (on_remove);
				}

				return widget;
			}

			private void on_remove (FederationBlockWidget widget, string federation_block_id) {
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
		}

		public class AddFederationBlockDialog : Adw.Dialog {
			~AddFederationBlockDialog () {
				debug ("Destroying AddFederationBlockDialog");
			}

			class SeverityObject : Object {
				public FederationBlock.Severity severity { get; set; }

				public SeverityObject (FederationBlock.Severity sev) {
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
					new SeverityObject (FederationBlock.Severity.SILENCE),
					new SeverityObject (FederationBlock.Severity.SUSPEND),
					new SeverityObject (FederationBlock.Severity.NOOP),
				});

				sev_row = new Adw.ComboRow () {
					// translators: Admin dashboard, federation block dialog severity row title
					title = _("Severity"),
					model = sev_model,
					factory = signallistitemfactory
				};
				sev_row.notify["selected"].connect (on_sev_change);

				rule_reject_media = new Gtk.CheckButton () {
					active = true
				};
				rule_reject_reports = new Gtk.CheckButton ();
				rule_obfuscate = new Gtk.CheckButton ();

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
				bool is_suspend = ((SeverityObject) sev_row.selected_item).severity == FederationBlock.Severity.SUSPEND;
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
				accepts = typeof (FederationBlock)
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
			~ReportDialog () {
				debug ("Destroying ReportDialog");
			}

			public signal void refresh ();

			Adw.PreferencesGroup profile_group;
			Adw.PreferencesPage page;
			Adw.ToastOverlay toast_overlay;
			Gtk.Button take_action_button;
			Gtk.Button resolve_button;
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

				var headerbar = new Adw.HeaderBar ();

				// translators: Admin dashboard, take action against user headerbar button
				take_action_button = new Gtk.Button.with_label (_("Take Action")) {
					css_classes = {"destructive-action"}
				};

				resolve_button = new Gtk.Button.with_label (_("Resolve")) {
					css_classes = {"suggested-action"}
				};

				headerbar.pack_end (take_action_button);
				headerbar.pack_start (resolve_button);

				toolbarview.add_top_bar (headerbar);

				profile_group = new Adw.PreferencesGroup ();
				page.add (profile_group);
				this.child = toolbarview;
			}

			public ReportDialog (Report report) {
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
					info_group.add (new Adw.ActionRow () {
						title = _("Assigned to"),
						subtitle = report.assigned_account == null ? _("Nobody") : report.assigned_account.account.full_handle,
						subtitle_selectable = true
					});
				}

				var report_category = Report.Category.from_string (report.category);
				info_group.add (new Adw.ActionRow () {
					title = _("Category"),
					subtitle = report_category.to_string (),
					subtitle_selectable = true
				});

				if (report_category == Report.Category.VIOLATION && report.rules.size > 0) {
					var rules_row = new Adw.ExpanderRow () {
						title = _("Violated Rules")
					};

					report.rules.foreach (rule => {
						rules_row.add_row (
							new Gtk.Label (rule.text) {
								wrap = true,
								xalign = 0.0f,
								wrap_mode = Pango.WrapMode.WORD_CHAR,
								margin_bottom = 8,
								margin_top = 8,
								margin_start = 8,
								margin_end = 8,
							}
						);

						return true;
					});

					info_group.add (rules_row);
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
				page.add (status_group);
			}
		}

		public class ReportWidget : Adw.ActionRow {
			~ReportWidget () {
				debug ("Destroying ReportWidget");
			}

			public signal void report_activated (Report report);
			Report report;
			public ReportWidget (Report report) {
				this.report = report;
				this.activated.connect (on_activate);
				this.activatable = true;
				this.overflow = Gtk.Overflow.HIDDEN;
				this.subtitle_lines = 0;
				this.title = report.target_account.account.full_handle;
				this.subtitle = "<b>%s:</b> %s\n<b>%s:</b> %d\n<b>%s:</b> %s".printf (
					// translators: 'Reported by: <account>'
					_("Reported by"),
					report.account.account.full_handle,
					// translators: 'Reported Posts: <amount>'
					_("Reported Posts"),
					report.statuses == null ? 0 : report.statuses.size,
					// translators: 'Assigned to: <account>'
					_("Assigned to"),

					report.assigned_account == null ? _("Nobody") : report.assigned_account.account.full_handle
				);

				this.add_prefix (new Widgets.Avatar () {
					account = report.target_account.account,
					size = 48
				});

				// translators: Admin dashboard, report status
				string status = _("No Limits");
				if (report.action_taken) {
					if (report.target_account.suspended) {
						status = _("Suspended");
					} else if (report.target_account.silenced) {
						status = _("Silenced");
					} else if (report.target_account.disabled) {
						status = _("Disabled");
					}
				}

				this.add_suffix (new Gtk.Label (status) {
					xalign = 1.0f,
					wrap = true,
					wrap_mode = Pango.WrapMode.WORD_CHAR,
					hexpand = true
				});
			}

			private void on_activate () {
				report_activated (report);
			}
		}

		public class Report : Entity, PaginationTimeline.BasicWidgetizable {
			public enum Category {
				SPAM,
				VIOLATION,
				LEGAL,
				OTHER;

				public static Category from_string (string cat) {
					switch (cat.down ()) {
						case "spam": return SPAM;
						case "violation": return VIOLATION;
						case "legal": return LEGAL;
						default: return OTHER;
					}
				}

				public string to_string () {
					switch (this) {
						case SPAM: return _("Spam");
						case VIOLATION: return _("Violation");
						case LEGAL: return _("Legal");
						default: return _("Other");
					}
				}

				public string to_api_string () {
					switch (this) {
						case SPAM: return "spam";
						case VIOLATION: return "violation";
						case LEGAL: return "legal";
						default: return "other";
					}
				}
			}

			public class AdminAccount : Entity {
				public string id { get; set; }
				public string username { get; set; }
				public string? domain { get; set; default=null; }
				public string email { get; set; }
				public string? ip { get; set; default=null; }
				public bool confirmed { get; set; }
				public bool suspended { get; set; }
				public bool disabled { get; set; }
				public bool silenced { get; set; }
				public bool approved { get; set; }
				public API.Account account { get; set; }
			}

			public string id { get; set; }
			public string category { get; set; default="other"; }
			public bool action_taken { get; set; }
			public string? action_taken_at { get; set; default=null; }
			public string comment { get; set; }
			public bool forwarded { get; set; }
			public string created_at { get; set; }
			public string? updated_at { get; set; default=null; }
			public AdminAccount account { get; set; }
			public AdminAccount target_account { get; set; }
			public AdminAccount? assigned_account { get; set; default=null; }
			public AdminAccount? action_taken_by_account { get; set; default=null; }
			public Gee.ArrayList<API.Status>? statuses { get; set; default=null; }
			public Gee.ArrayList<API.Instance.Rule>? rules { get; set; default=null; }

			public override Type deserialize_array_type (string prop) {
				switch (prop) {
					case "statuses":
						return typeof (API.Status);
					case "rules":
						return typeof (API.Instance.Rule);
				}

				return base.deserialize_array_type (prop);
			}

			public override Gtk.Widget to_widget () {
				return new ReportWidget (this);
			}
		}

		public class ReportTimeline : PaginationTimeline {
			~ReportTimeline () {
				debug ("Destroying ReportTimeline");
			}

			public signal void on_open_report_dialog (Report report);
			public override Gtk.Widget on_create_model_widget (Object obj) {
				Gtk.Widget widget = base.on_create_model_widget (obj);
				var action_row = widget as ReportWidget;
				if (action_row != null) {
					action_row.report_activated.connect (on_report_activated);
				}

				return widget;
			}

			private void on_report_activated (Report report) {
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
				accepts = typeof (Report)
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

		private void open_report_dialog (Report report) {
			var report_dialog = new ReportDialog (report);
			report_dialog.refresh.connect (refresh);
			report_dialog.present (this.admin_window);
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
