public class Tuba.API.GroupedNotificationsResults : Entity {
	public class NotificationGroup : API.Notification, Widgetizable {
		//  public int64 most_recent_notification_id { get; set; }
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

		public NotificationGroup.from_notification (API.Notification notification) {
			this.patch (notification);
			//  this.most_recent_notification_id = notification.id;
			this.sample_account_ids = new Gee.ArrayList<string>.wrap ({notification.account.id});
			if (notification.status != null) this.status_id = notification.status.id;
			this.tuba_accounts = new Gee.ArrayList<API.Account>.wrap ({notification.account});
		}

		public override Gtk.Widget to_widget () {
			if (tuba_accounts.size == 1 || group_key.has_prefix ("ungrouped-")) return base.to_widget ();
			switch (this.kind) {
				case InstanceAccount.KIND_FOLLOW:
				case InstanceAccount.KIND_ADMIN_SIGNUP:
					return create_basic_card ();
				default:
					return new Widgets.GroupedNotification (this);
			}
		}

		private Gtk.Widget create_basic_card () {
			var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 16) {
				margin_top = 8,
				margin_bottom = 8,
				margin_start = 16,
				margin_end = 16
			};
			Tuba.InstanceAccount.Kind res_kind;
			var sub_box = Widgets.GroupedNotification.group_box (this, this.kind, out res_kind);

			var group_icon = new Gtk.Image.from_icon_name (res_kind.icon) {
				margin_bottom = 22,
				margin_top = 3,
				css_classes = {"grouped-icon"},
				halign = CENTER
			};

			switch (this.kind) {
				case InstanceAccount.KIND_FAVOURITE:
					group_icon.add_css_class ("star");
					break;
				case InstanceAccount.KIND_REBLOG:
					group_icon.add_css_class ("reblog");
					break;
				case InstanceAccount.KIND_ADMIN_SIGNUP:
					group_icon.add_css_class ("sign-up");
					break;
				case InstanceAccount.KIND_FOLLOW:
				case InstanceAccount.KIND_FOLLOW_REQUEST:
					group_icon.add_css_class ("follow");
					break;
			}

			box.append (group_icon);
			box.append (sub_box);

			var row = new Widgets.ListBoxRowWrapper () {
				child = box,
				activatable = false
			};
			return row;
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
