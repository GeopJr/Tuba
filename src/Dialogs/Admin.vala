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
			title = _("Reports")
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

		public static Place place_federation = new Place () {
			icon = "user-home-symbolic",
			title = _("Federation"),
		};

		construct {
			this.transient_for = app.main_window;
			this.modal = true;

			items.append (new Views.Sidebar.ItemRow (place_dash));
			if (accounts.active != null && accounts.active.admin_mode && accounts.active.role != null && accounts.active.role.permissions != null) {
				admin_permissions = new API.AccountRole.Permissions.from_string (accounts.active.role.permissions);

				if (admin_permissions.admin || admin_permissions.reports)
					items.append (new Views.Sidebar.ItemRow (place_reports));

				if (admin_permissions.admin || admin_permissions.federation)
					items.append (new Views.Sidebar.ItemRow (place_federation));

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
