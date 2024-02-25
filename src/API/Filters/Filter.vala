public class Tuba.API.Filters.Filter : Entity {
	public string id { get; set; }
	public string title { get; set; }
	public Gee.ArrayList<string> context { get; set; }
	public string? expires_at { get; set; default=null; }
	public string filter_action { get; set; }
	public Gee.ArrayList<FilterKeyword> keywords { get; set; }
	public Gee.ArrayList<FilterStatus> statuses { get; set; }

	public static Filter from (Json.Node node) throws Error {
		return Entity.from_json (typeof (Filter), node) as Filter;
	}

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "context":
				return Type.STRING;
			case "keywords":
				return typeof (FilterKeyword);
			case "statuses":
				return typeof (FilterStatus);
		}

		return base.deserialize_array_type (prop);
	}

	public bool tuba_hidden {
		get {
			return filter_action != "warn";
		}
	}

	public enum ContextType {
		HOME,
		NOTIFICATIONS,
		PUBLIC,
		THREAD,
		ACCOUNT;

		public string to_string () {
			switch (this) {
				case HOME: return _("Home &amp; Lists");
				case NOTIFICATIONS: return _("Notifications");
				case PUBLIC: return _("Public Timelines");
				case THREAD: return _("Conversations");
				case ACCOUNT: return _("Profiles");
				default: assert_not_reached ();
			}
		}

		public string to_api () {
			switch (this) {
				case HOME: return "home";
				case NOTIFICATIONS: return "notifications";
				case PUBLIC: return "public";
				case THREAD: return "thread";
				case ACCOUNT: return "account";
				default: assert_not_reached ();
			}
		}

		public static ContextType? from_string (string context_string) {
			switch (context_string.down ()) {
				case "home":
					return HOME;
				case "notifications":
					return NOTIFICATIONS;
				case "public":
					return PUBLIC;
				case "thread":
					return THREAD;
				case "account":
					return ACCOUNT;
				default:
					return null;
			}
		}
	}
}
