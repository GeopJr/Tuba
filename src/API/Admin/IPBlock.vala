public class Tuba.API.Admin.IPBlock : Entity, BasicWidgetizable {
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
		return new Widgets.Admin.IPBlock (this);
	}
}
