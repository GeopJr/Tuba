public class Tuba.Widgets.Tag : Adw.ActionRow {
	public string name { get; set; }
	public Tag (API.Tag tag) {
		this.name =
		this.title = @"#$(tag.name)";
		this.activatable = true;
		this.use_markup = false;

		if (tag.history != null && tag.history.size > 0) {
			var last_history_entry = tag.history.get (0);
			//  var total_uses = int.parse (last_history_entry.uses);
			var total_accounts = int.parse (last_history_entry.accounts);
			// translators: Shown as a hashtag subtitle. The variable is the number of people that used a hashtag
			var subtitle = GLib.ngettext ("%d person yesterday", "%d people yesterday", (ulong) total_accounts).printf (total_accounts);

			if (tag.history.size > 1) {
				last_history_entry = tag.history.get (1);
				//  total_uses += int.parse (last_history_entry.uses);
				total_accounts += int.parse (last_history_entry.accounts);

				// translators: Shown as a hashtag subtitle. The variable is the number of people that used a hashtag
				subtitle = GLib.ngettext ("%d person in the past 2 days", "%d people in the past 2 days", (ulong) total_accounts).printf (total_accounts);
			}

			this.subtitle = subtitle;
		}
	}
}
