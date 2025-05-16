public class Tuba.API.GroupedNotificationsResults : Entity {
	public class NotificationGroup : API.Notification, Widgetizable {
		public string most_recent_notification_id { get; set; }
		public Gee.ArrayList<string> sample_account_ids { get; set; }
		public string? status_id { get; set; default = null; }
		public Gee.ArrayList<API.Account> tuba_accounts { get; set; }

		public override Type deserialize_array_type (string prop) {
			switch (prop) {
				case "sample-account-ids":
					return Type.STRING;
			}

			return base.deserialize_array_type (prop);
		}

		public override Gtk.Widget to_widget () {
			if (tuba_accounts.size == 1) return base.to_widget ();

			var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
			var avi_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
			box.append (avi_box);
			box.append (base.to_widget ());

			foreach (var account in tuba_accounts) {
				avi_box.append (new Widgets.Avatar () {
					account = account,
					size = 30,
					overflow = Gtk.Overflow.HIDDEN,
					allow_mini_profile = true
				});
			}

			return box;
		}
	}

	public Gee.ArrayList<API.Account> accounts { get; set; }
	public Gee.ArrayList<API.Status> statuses { get; set; }
	public Gee.ArrayList<NotificationGroup> notification_groups { get; set; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "accounts":
				return typeof (API.Account);
			case "statuses":
				return typeof (API.Status);
			case "notification-groups":
				return typeof (NotificationGroup);
		}

		return base.deserialize_array_type (prop);
	}

	public static GroupedNotificationsResults from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.GroupedNotificationsResults), node) as API.GroupedNotificationsResults;
	}
}
