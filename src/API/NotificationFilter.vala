public class Tuba.API.NotificationFilter {
	public class Policy : Entity {
		public class Summary : Entity {
			public int32 pending_requests_count { get; set; default=0; }
			public int32 pending_notifications_count { get; set; default=0; }
		}

		public bool filter_not_following { get; set; default=false; }
		public bool filter_not_followers { get; set; default=false; }
		public bool filter_new_accounts { get; set; default=false; }
		public bool filter_private_mentions { get; set; default=false; }
		public Summary? summary { get; set; default=null; }

		public static Policy from (Json.Node node) throws Error {
			return Entity.from_json (typeof (Policy), node) as Policy;
		}
	}

	public class Request : Entity, Widgetizable {
		public string id { get; set; }
		//  public string created_at { get; set; }
		//  public string? updated_at { get; set; default=null; }
		public string notifications_count { get; set; default="0"; }
		public API.Account account { get; set; }

		public override Gtk.Widget to_widget () {
			return new Widgets.NotificationRequest (this);
		}

		public static Request from (Json.Node node) throws Error {
			return Entity.from_json (typeof (Request), node) as Request;
		}
	}
}
