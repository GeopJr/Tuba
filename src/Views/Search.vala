using Gtk;

public class Tootle.Views.Search : Views.TabbedBase {

	public string query { get; set; default = ""; }
	Hdy.SearchBar bar;
	Hdy.Clamp bar_clamp;
	SearchEntry entry;

	Views.Base accounts_tab;
	Views.Base statuses_tab;
	Views.Base hashtags_tab;

	public Search () {
		Object (label: _("Search"));

		bar = new Hdy.SearchBar ();
		bar.search_mode_enabled = true;
		bar.show ();
		pack_start (bar, false, false, 0);
		reorder_child (bar, 2);

		entry = new SearchEntry ();
		entry.width_chars = 25;
		entry.text = query;
		entry.show ();

		bar_clamp = new Hdy.Clamp ();
		bar_clamp.show ();
		bar_clamp.add (entry);

		bar.add (bar_clamp);
		bar.connect_entry (entry);

		entry.activate.connect (() => request ());
		entry.icon_press.connect (() => {
			entry.text = "";
			request ();
		});
		entry.grab_focus_without_selecting ();
		status_button.clicked.connect (request);

		accounts_tab = add_list_tab (_("Accounts"), "system-users-symbolic");
		statuses_tab = add_list_tab (_("Statuses"), "user-available-symbolic");
		hashtags_tab = add_list_tab (_("Hashtags"), "emoji-flags-symbolic");

		request ();
	}

	bool append (Views.Base tab, owned Entity entity) {
		var w = entity.to_widget ();
		tab.content_list.insert (w, -1);
		return true;
	}

	void request () {
		query = entry.text.chug ().chomp ();
		if (query == "") {
			clear ();
			state = "status";
			status_message = _("Enter query");
			return;
		}

		clear ();
		state = "status";
		status_message = STATUS_LOADING;
		API.SearchResults.request.begin (query, accounts.active, (obj, res) => {
			try {
				var results = API.SearchResults.request.end (res);

				if (!results.accounts.is_empty) {
					results.accounts.@foreach (e => append (accounts_tab, e));
				}
				if (!results.statuses.is_empty) {
					results.statuses.@foreach (e => append (statuses_tab, e));
				}
				if (!results.hashtags.is_empty) {
					results.hashtags.@foreach (e => append (hashtags_tab, e));
				}

				on_content_changed ();
			}
			catch (Error e) {
				on_error (-1, e.message);
			}
		});
	}

}
