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
				win.split_view.show_content = true;
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
		};

		public static Place place_ip_rules = new Place () {
			icon = "user-home-symbolic",
			title = _("IP Rules"),
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
		}
	}

	private class BasePage : Adw.NavigationPage {
		private Adw.PreferencesPage page;
		private Gtk.ScrolledWindow scroller;
		private Gtk.Spinner spinner;
		private Adw.ToastOverlay toast_overlay;

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

			var toolbar_view = new Adw.ToolbarView () {
				content = toast_overlay
			};
			toolbar_view.add_top_bar (new Adw.HeaderBar ());

			this.child = toolbar_view;
		}

		protected virtual void add_to_page (Adw.PreferencesGroup group) {
			page.add (group);
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

	//  private class Reports : BasePage {
	//  	construct {

	//  	}
	//  }

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
