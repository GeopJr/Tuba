public class Tuba.API.Admin.Report : Entity, BasicWidgetizable {
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
				case VIOLATION: return _("Rule Violation");
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

	public string id { get; set; }
	public string category { get; set; default="other"; }
	public bool action_taken { get; set; }
	public string? action_taken_at { get; set; default=null; }
	public string comment { get; set; default=""; }
	public bool forwarded { get; set; }
	public string created_at { get; set; }
	public string? updated_at { get; set; default=null; }
	public API.Admin.Account account { get; set; }
	public API.Admin.Account target_account { get; set; }
	public API.Admin.Account? assigned_account { get; set; default=null; }
	public API.Admin.Account? action_taken_by_account { get; set; default=null; }
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
		return new Widgets.Admin.Report (this);
	}

	public static Report from (Json.Node node) throws Error {
		return Entity.from_json (typeof (Report), node) as Report;
	}

	public string to_string (string? created_at) {
		// translators: the variable is a string report comment
		string t_comment = comment == "" ? comment : "\n%s: <b>%s</b>".printf (_("With the comment"), comment);
		// translators: report notification, "Reason: <reason>"
		string t_reason = "%s: <b>%s</b>".printf (_("Reason"), Category.from_string (category).to_string ());

		string msg = created_at == null
			// translators: report notification
			? "%s\n".printf (_("You've received a report"))

			// translators: report notification with date, "You've received a report on: <date>"
			: "%s: <b>%s</b>\n".printf (_("You've received a report on"), Utils.DateTime.format_full (created_at));

		return @"$msg$t_reason$t_comment";
	}
}
