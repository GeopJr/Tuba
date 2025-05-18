public class Tuba.Widgets.GroupedNotification : Widgets.Notification {
	public GroupedNotification (API.GroupedNotificationsResults.NotificationGroup obj) {
		var old_kind = obj.kind;
		base (obj, false);
		if (obj.tuba_accounts.size == 0) return;

		Tuba.InstanceAccount.Kind res_kind;
		var box = group_box (obj, old_kind, out res_kind);
		avatar_side.prepend (new Gtk.Image.from_icon_name (res_kind.icon) {
			icon_size = Gtk.IconSize.LARGE,
			margin_bottom = 26
		});
		content_side.prepend (box);
	}

	public static Gtk.Box group_box (API.GroupedNotificationsResults.NotificationGroup obj, string old_kind, out Tuba.InstanceAccount.Kind res_kind) {
		Gee.HashMap<string, string>? mojis = null;

		string kind_actor_name;
		switch (obj.tuba_accounts.size - 1) {
			case 0:
				kind_actor_name = obj.tuba_accounts.get (0).display_name;
				mojis = obj.tuba_accounts.get (0).emojis_map;
				break;
			case 1:
				mojis = new Gee.HashMap<string, string> ();
				var acc_1 = obj.tuba_accounts.get (0);
				var acc_2 = obj.tuba_accounts.get (1);
				string diffed_name_1 = acc_1.display_name;
				string diffed_name_2 = acc_2.display_name;

				if (acc_1.emojis != null && acc_1.emojis.size > 0) {
					foreach (var e in acc_1.emojis) {
						string new_name = @"tuba_1_$(e.shortcode)";
						diffed_name_1 = diffed_name_1.replace (@":$(e.shortcode):", @":$new_name:");
						mojis.set (new_name, e.url);
					}
				}

				if (acc_2.emojis != null && acc_2.emojis.size > 0) {
					foreach (var e in acc_2.emojis) {
						string new_name = @"tuba_2_$(e.shortcode)";
						diffed_name_2 = diffed_name_2.replace (@":$(e.shortcode):", @":$new_name:");
						mojis.set (new_name, e.url);
					}
				}

				kind_actor_name = "%s & %s".printf (diffed_name_1, diffed_name_2);
				break;
			default:
				kind_actor_name = _("%s (& %d others)").printf (obj.tuba_accounts.get (0).display_name, obj.tuba_accounts.size - 1);
				mojis = obj.tuba_accounts.get (0).emojis_map;
				break;
		}

		accounts.active.describe_kind (
			old_kind,
			out res_kind,
			kind_actor_name,
			null,
			obj.emoji
		);

		var title_label = new Widgets.EmojiLabel () {
			use_markup = false,
			ellipsize = true,
			css_classes = {"dim-label", "font-bold", "ttl-status-heading"}
		};
		title_label.instance_emojis = mojis;
		title_label.content = res_kind.description;

		var avi_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 3);
		for (int i = 0; i < int.min (6, obj.tuba_accounts.size); i++) {
			var avi = new Widgets.Avatar () {
				account = obj.tuba_accounts.get (i),
				size = 30,
				overflow = Gtk.Overflow.HIDDEN,
				allow_mini_profile = true
			};
			avi.mini_clicked.connect (on_open_sub_account);
			avi_box.append (avi);
		}

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
		box.append (avi_box);
		box.append (title_label);

		return box;
	}

	private static void on_open_sub_account (API.Account? acc) {
		acc.open ();
	}
}
