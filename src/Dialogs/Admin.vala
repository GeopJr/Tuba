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

		public static Place place_dash = new Place () {
			icon = "user-home-symbolic",
			title = _("Dashboard"),
			open_func_admin = (win) => {
				win.split_view.content = new Dashboard ();
			}
		};

		public static Place place_server_settings = new Place () {
			icon = "user-home-symbolic",
			title = _("Server Settings"),
		};

		public static Place place_rules = new Place () {
			icon = "user-home-symbolic",
			title = _("Server Rules"),
		};

		public static Place place_roles = new Place () {
			icon = "user-home-symbolic",
			title = _("Roles"),
		};

		public static Place place_announcements = new Place () {
			icon = "user-home-symbolic",
			title = _("Announcements"),
		};

		public static Place place_custom_emojis = new Place () {
			icon = "user-home-symbolic",
			title = _("Custom Emojis"),

		};

		public static Place place_reports = new Place () {
			icon = "user-home-symbolic",
			title = _("Reports"),
			separated = true
		};


		public static Place place_accounts = new Place () {
			icon = "user-home-symbolic",
			title = _("Accounts"),

		};

		public static Place place_invites = new Place () {
			icon = "user-home-symbolic",
			title = _("Invites"),

		};

		public static Place place_follow_recomendations = new Place () {
			icon = "user-home-symbolic",
			title = _("Follow Recomendations"),

		};

		public static Place place_federation = new Place () {
			icon = "user-home-symbolic",
			title = _("Federation"),

		};

		public static Place place_blocked_email_domains = new Place () {
			icon = "user-home-symbolic",
			title = _("Blocked E-mail Domains"),

		};

		public static Place place_ip_rules = new Place () {
			icon = "user-home-symbolic",
			title = _("IP Rules"),

		};

		public static Place place_audit_log = new Place () {
			icon = "user-home-symbolic",
			title = _("Audit Log"),

		};

		public static Place place_webhooks = new Place () {
			icon = "user-home-symbolic",
			title = _("Webhooks"),

		};

		public static Place place_relay = new Place () {
			icon = "user-home-symbolic",
			title = _("Relay"),

		};

		protected GLib.ListStore items_model;
		construct {
			app.add_window (this);

			items_model = new GLib.ListStore (typeof (Place));
			items_model.append (place_dash);
			items_model.append (place_server_settings);
			items_model.append (place_rules);
			items_model.append (place_roles);
			items_model.append (place_announcements);
			items_model.append (place_custom_emojis);
			items_model.append (place_webhooks);
			items_model.append (place_relay);

			items_model.append (place_reports);
			items_model.append (place_accounts);
			items_model.append (place_invites);
			items_model.append (place_follow_recomendations);
			items_model.append (place_federation);
			items_model.append (place_blocked_email_domains);
			items_model.append (place_ip_rules);
			items_model.append (place_audit_log);

			// TODO: dispose on close
			items.bind_model (items_model, on_item_create);
			items.set_header_func (on_item_header_update);

			present ();
		}

		Gtk.Widget on_item_create (Object obj) {
			return new Views.Sidebar.ItemRow (obj as Place);
		}

		[GtkCallback] void on_item_activated (Gtk.ListBoxRow _row) {
			var row = _row as Views.Sidebar.ItemRow;
			if (row == null) return;

			var place = row.place as Place;
			if (place != null && place.open_func_admin != null)
				place.open_func_admin (this);
		}

		void on_item_header_update (Gtk.ListBoxRow _row, Gtk.ListBoxRow? _before) {
			var row = _row as Views.Sidebar.ItemRow;
			var before = _before as Views.Sidebar.ItemRow;

			row.set_header (null);

			if (row.place.separated && before != null && !before.place.separated) {
				row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
					css_classes = { "ttl-separator" }
				});
			}
		}
	}

	private class Dashboard : Adw.NavigationPage {
		private Adw.PreferencesPage page;
		construct {
			this.title = _("Dashboard");

			page = new Adw.PreferencesPage () {
				hexpand = true,
				vexpand = true,
				valign = Gtk.Align.CENTER
			};

			this.child = new Adw.ToolbarView () {
				content = new Gtk.ScrolledWindow () {
					vexpand = true,
					hexpand = true,
					child = page
				}
			};

			populate_software ();
			populate_space ();
		}

		private void populate_software () {
			new Request.POST ("/api/v1/admin/dimensions")
				.with_account (accounts.active)
				.body_json (Dialogs.Admin.get_dimensions_body ("software_versions", 4))
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					var node = network.parse_node (parser);
					var dimension = API.Admin.Dimension.from (node);

					if (dimension.key == "software_versions" && dimension.data != null && dimension.data.size > 0) {
						var softawre_group = new Adw.PreferencesGroup () {
							title = _("Software")
						};

						foreach (var software_entry in dimension.data) {
							softawre_group.add (
								new Adw.ActionRow () {
									title = software_entry.human_key,
									subtitle = software_entry.human_value,
									use_markup = false
								}
							);
						}

						page.add (softawre_group);
					}
				})
				.exec ();
		}

		private void populate_space () {
			new Request.POST ("/api/v1/admin/dimensions")
				.with_account (accounts.active)
				.body_json (Dialogs.Admin.get_dimensions_body ("space_usage", 3))
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					var node = network.parse_node (parser);
					var dimension = API.Admin.Dimension.from (node);

					if (dimension.key == "space_usage" && dimension.data != null && dimension.data.size > 0) {
						var space_group = new Adw.PreferencesGroup () {
							title = _("Space Usage")
						};

						foreach (var space_entry in dimension.data) {
							space_group.add (
								new Adw.ActionRow () {
									title = space_entry.human_key,
									subtitle = space_entry.human_value,
									use_markup = false
								}
							);
						}

						page.add (space_group);
					}
				})
				.exec ();
		}
	}

	private static Json.Builder get_dimensions_body (string key, int limit = 4) {
		var now = new GLib.DateTime.now_local ();
		var end = now.add_months (1).add_days (-1);

		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("start_at");
		builder.add_string_value (now.format ("%F"));

		builder.set_member_name ("key");
		builder.add_string_value (key);

		builder.set_member_name ("limit");
		builder.add_int_value (limit);


		builder.set_member_name ("end_at");
		builder.add_string_value (end.format ("%F"));

		builder.end_object ();

		return builder;
	}
}
