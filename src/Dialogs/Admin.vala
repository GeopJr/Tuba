[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/admin_dashboard.ui")]
public class Tuba.Dialogs.Admin.Window : Adw.Window {
	public class Place : Tuba.Place {
		[CCode (has_target = false)]
		public delegate void OpenFuncAdmin (Window window);
		public OpenFuncAdmin open_func_admin { get; set; }
	}

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
			win.split_view.content = new Views.Admin.Page.Dashboard ();
		}
	};

	public static Place place_reports = new Place () {
		icon = "tuba-police-badge2-symbolic",
		title = _("Reports"),
		open_func_admin = (win) => {
			win.split_view.content = new Views.Admin.Page.Reports () {
				admin_window = win
			};
		}
	};

	public static Place place_accounts = new Place () {
		icon = "tuba-people-symbolic",
		title = _("Accounts"),
		open_func_admin = (win) => {
			win.split_view.content = new Views.Admin.Page.Accounts () {
				admin_window = win
			};
		}
	};

	public static Place place_blocked_email_domains = new Place () {
		icon = "tuba-mail-unread-symbolic",
		title = _("Blocked E-mail Domains"),
		open_func_admin = (win) => {
			win.split_view.content = new Views.Admin.Page.BlockedEmails () {
				admin_window = win
			};
		}
	};

	public static Place place_ip_rules = new Place () {
		icon = "network-server-symbolic",
		title = _("IP Rules"),
		open_func_admin = (win) => {
			win.split_view.content = new Views.Admin.Page.BlockedIPs () {
				admin_window = win
			};
		}
	};

	public static Place place_federation_allow = new Place () {
		icon = "tuba-check-round-outline-symbolic",
		title = _("Federation Allowlist"),
		open_func_admin = (win) => {
			win.split_view.content = new Views.Admin.Page.FederationAllowList () {
				admin_window = win
			};
		}
	};

	public static Place place_federation_deny = new Place () {
		icon = "tuba-cross-large-symbolic",
		title = _("Federation Blocklist"),
		open_func_admin = (win) => {
			win.split_view.content = new Views.Admin.Page.FederationBlockList () {
				admin_window = win
			};
		}
	};

	bool has_reports = false;
	construct {
		this.transient_for = app.main_window;
		this.modal = true;

		items.append (new Views.Sidebar.ItemRow (place_dash));
		if (accounts.active != null && accounts.active.admin_mode && accounts.active.role != null && accounts.active.role.permissions != null) {
			admin_permissions = new API.AccountRole.Permissions.from_string (accounts.active.role.permissions);

			if (admin_permissions.admin || admin_permissions.reports) {
				items.append (new Views.Sidebar.ItemRow (place_reports));
				has_reports = true;
			}

			if (admin_permissions.admin || admin_permissions.users)
				items.append (new Views.Sidebar.ItemRow (place_accounts));

			if (admin_permissions.admin || admin_permissions.federation) {
				items.append (new Views.Sidebar.ItemRow (place_federation_allow));
				items.append (new Views.Sidebar.ItemRow (place_federation_deny));
			}

			if (admin_permissions.admin || admin_permissions.blocks) {
				items.append (new Views.Sidebar.ItemRow (place_blocked_email_domains));
				items.append (new Views.Sidebar.ItemRow (place_ip_rules));
			}
		}

		split_view.content = new Views.Admin.Page.Dashboard ();
	}

	public void open_reports () {
		if (has_reports) {
			place_reports.open_func_admin (this);
			items.select_row (items.get_row_at_index (1));
		}
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
