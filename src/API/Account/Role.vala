public class Tuba.API.AccountRole : Entity {
	public class Permissions : Object {
		[Flags]
		enum Permissions {
			ADMINISTRATOR,
			DEVOPS,
			VIEW_AUDIT_LOG,
			VIEW_DASHBOARD,
			MANAGE_REPORTS,
			MANAGE_FEDERATION,
			MANAGE_SETTINGS,
			MANAGE_BLOCKS,
			MANAGE_TAXONOMIES,
			MANAGE_APPEALS,
			MANAGE_USERS,
			MANAGE_INVITES,
			MANAGE_RULES,
			MANAGE_ANNOUNCEMENTS,
			MANAGE_CUSTOM_EMOJIS,
			MANAGE_WEBHOOKS,
			INVITE_USERS,
			MANAGE_ROLES,
			MANAGE_USER_ACCESS,
			DELETE_USER_DATA;
		}

		int bitmask = 0;
		public Permissions.from_string (string bitmask) {
			this.bitmask = int.parse (bitmask);
		}

		public bool admin {
			get {
				return Permissions.ADMINISTRATOR in bitmask;
			}
		}

		public bool dashboard {
			get {
				return Permissions.VIEW_DASHBOARD in bitmask;
			}
		}

		public bool reports {
			get {
				return Permissions.MANAGE_REPORTS in bitmask;
			}
		}

		public bool appeals {
			get {
				return Permissions.MANAGE_APPEALS in bitmask;
			}
		}

		public bool users {
			get {
				return Permissions.MANAGE_USERS in bitmask;
			}
		}

		public bool blocks {
			get {
				return Permissions.MANAGE_BLOCKS in bitmask;
			}
		}

		public bool federation {
			get {
				return Permissions.MANAGE_FEDERATION in bitmask;
			}
		}
	}

	public string id { get; set; default = ""; }
	public string name { get; set; default = ""; }
	public string? permissions { get; set; default = null; }
	// Ignore for now
	//  public string color { get; set; default = ""; }

	public Gtk.Widget to_widget () {
		return new Gtk.Label (name) {
			wrap = true,
			wrap_mode = Pango.WrapMode.WORD_CHAR,
			css_classes = { "profile-role", "profile-role-border-radius" }
		};
	}
}
