using Gtk;

public class Tooth.Views.Search : Views.TabbedBase {

	public string query { get; set; default = ""; }
	protected SearchBar bar;
	protected Adw.Clamp bar_clamp;
	protected SearchEntry entry;

	Views.ContentBase accounts_tab;
	Views.ContentBase statuses_tab;
	Views.ContentBase hashtags_tab;

	public Search () {
		Object (label: _("Search"));

		bar = new SearchBar () {
			search_mode_enabled = true
		};
		prepend (bar);
		reorder_child_after (bar, header);

		entry = new SearchEntry () {
			width_chars = 25,
			text = query
		};

		bar_clamp = new Adw.Clamp () {
			child = entry
		};

		bar.child = bar_clamp;
		bar.connect_entry (entry);

		entry.activate.connect (() => request ());
		status_button.clicked.connect (request);

		accounts_tab = add_list_tab (_("Accounts"), "tooth-people-symbolic");
		statuses_tab = add_list_tab (_("Statuses"), "tooth-chat-symbolic");
		hashtags_tab = add_list_tab (_("Hashtags"), "tooth-hashtag-symbolic");

		request ();
	}

	bool append_entity (Views.ContentBase tab, owned Entity entity) {
		tab.model.append (entity);
		return true;
	}

	void request () {
		query = entry.text.chug ().chomp ();
		if (query == "") {
			clear ();
			state = "status";
			status_title = _("Enter Query");
			return;
		}

		clear ();
		state = "status";
		status_loading = true;
		API.SearchResults.request.begin (query, accounts.active, (obj, res) => {
			try {
				var results = API.SearchResults.request.end (res);

				if (!results.accounts.is_empty) {
					results.accounts.@foreach (e => append_entity (accounts_tab, e));
				}
				if (!results.statuses.is_empty) {
					results.statuses.@foreach (e => append_entity (statuses_tab, e));
				}
				if (!results.hashtags.is_empty) {
					results.hashtags.@foreach (e => append_entity (hashtags_tab, e));
				}

				status_title = STATUS_EMPTY;

				on_content_changed ();
			}
			catch (Error e) {
				on_error (-1, e.message);
			}
		});
	}

}
