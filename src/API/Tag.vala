using Gtk;

public class Tuba.API.Tag : Entity, Widgetizable {

    public string name { get; set; }
    public string url { get; set; }
	public Gee.ArrayList<API.TagHistory>? history { get; set; default = null; }
	public bool following { get; set; default = false; }

	public static Tag from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Tag), node) as API.Tag;
	}

	public override void open () {
	}

	public override Widget to_widget () {
		var w = new Adw.ActionRow () {
			title = @"#$name",
			activatable = true
		};
		if (history != null && history.size > 0) {
			var last_history_entry = history.get(0);
			var total_uses = int.parse (last_history_entry.uses);
			var total_accounts = int.parse (last_history_entry.accounts);
			// translators: the variables are numbers
			var subtitle = _("Used %d times by %d people yesterday").printf (total_uses, total_accounts);

			if (history.size > 1) {
				last_history_entry = history.get(1);
				total_uses += int.parse (last_history_entry.uses);
				total_accounts += int.parse (last_history_entry.accounts);

				// translators: the variables are numbers
				subtitle = _("Used %d times by %d people in the past 2 days").printf (total_uses, total_accounts);
			}

			w.subtitle = subtitle;
		}
		w.activated.connect(on_activated);
		return w;
	}

	protected void on_activated () {
		app.main_window.open_view (new Views.Hashtag (name, following));
	}
}
