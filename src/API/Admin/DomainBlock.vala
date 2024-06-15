public class Tuba.API.Admin.DomainBlock : Entity, BasicWidgetizable {
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
		return new Widgets.Admin.DomainBlock (this);
	}
}
