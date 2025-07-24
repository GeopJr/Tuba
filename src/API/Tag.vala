public class Tuba.API.Tag : Entity, Widgetizable {

	public string name { get; set; }
	public string url { get; set; }
	public Gee.ArrayList<API.TagHistory>? history { get; set; default = null; }
	public bool following { get; set; default = false; }
	public bool featuring { get; set; default = false; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "history":
				return typeof (API.TagHistory);
		}

		return base.deserialize_array_type (prop);
	}

	public static Tag from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Tag), node) as API.Tag;
	}

	public static Request search (string query) throws Error {
		return new Request.GET ("/api/v2/search")
			.with_account (accounts.active)
			.with_param ("q", query)
			.with_param ("resolve", "hashtags")
			.with_param ("exclude_unreviewed", "true")
			.with_param ("limit", "4");
	}

	public override void open () {
		#if USE_LISTVIEW
			app.main_window.open_view (new Views.Hashtag (name, following, Path.get_basename (url), this.featuring));
		#endif
	}

	public string weekly_use () {
		int used_times = 0;

		if (history != null && history.size >= 7) {
			for (var i = 0; i < 7; i++) {
				used_times += int.parse (history.get (i).uses);
			}
		}
		// translators: the variable is the amount of times a hashtag was used in a week
		//				in the composer auto-complete popup (so keep it short)
		return GLib.ngettext ("%d per week", "%d per week", (ulong) used_times).printf (used_times);
	}

	public override Gtk.Widget to_widget () {
		var w = new Adw.ActionRow () {
			title = @"#$name",
			activatable = true,
			use_markup = false
		};

		if (history != null && history.size > 0) {
			var last_history_entry = history.get (0);
			//  var total_uses = int.parse (last_history_entry.uses);
			var total_accounts = int.parse (last_history_entry.accounts);
			// translators: Shown as a hashtag subtitle. The variable is the number of people that used a hashtag
			var subtitle = GLib.ngettext ("%d person yesterday", "%d people yesterday", (ulong) total_accounts).printf (total_accounts);

			if (history.size > 1) {
				last_history_entry = history.get (1);
				//  total_uses += int.parse (last_history_entry.uses);
				total_accounts += int.parse (last_history_entry.accounts);

				// translators: Shown as a hashtag subtitle. The variable is the number of people that used a hashtag
				subtitle = GLib.ngettext ("%d person in the past 2 days", "%d people in the past 2 days", (ulong) total_accounts).printf (total_accounts);
			}

			w.subtitle = subtitle;
		}

		#if !USE_LISTVIEW
			w.activated.connect (on_activated);
		#endif

		return w;
	}

	#if !USE_LISTVIEW
		protected void on_activated () {
			app.main_window.open_view (new Views.Hashtag (name, following, Path.get_basename (url), this.featuring));
		}
	#endif

	//  public Request feature (bool? feature = null) {
	//  	string endpoint = "feature";
	//  	if (feature == null) {
	//  		endpoint = this.featuring ? "unfeature" : "feature";
	//  	} else if (feature == false) {
	//  		endpoint = "unfeature";
	//  	}

	//  	return new Request.POST (@"/api/v1/tags/$(Path.get_basename (url) ?? name)/$endpoint")
	//  		.with_account (accounts.active);
	//  }
}
