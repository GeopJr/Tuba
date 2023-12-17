public class Tuba.Views.Search : Views.TabbedBase {

	public string query { get; set; default = ""; }
	protected Gtk.SearchBar bar;
	protected Adw.Clamp bar_clamp;
	protected Gtk.SearchEntry entry;

	Views.ContentBase all_tab;
	Views.ContentBase accounts_tab;
	Views.ContentBase statuses_tab;
	Views.ContentBase hashtags_tab;

	construct {
		label = _("Search");

		bar = new Gtk.SearchBar () {
			search_mode_enabled = true
		};
		toolbar_view.add_top_bar (bar);

		entry = new Gtk.SearchEntry () {
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

		// translators: as in All search results
		all_tab = add_list_tab (_("All"), "tuba-loupe-large-symbolic");
		accounts_tab = add_list_tab (_("Accounts"), "tuba-people-symbolic");
		statuses_tab = add_list_tab (_("Posts"), "tuba-chat-symbolic");
		hashtags_tab = add_list_tab (_("Hashtags"), "tuba-hashtag-symbolic");

		uint timeout = 0;
		timeout = Timeout.add (200, () => {
			entry.grab_focus ();
			GLib.Source.remove (timeout);

			return true;
		}, Priority.LOW);

		request ();
	}

	bool append_entity (Views.ContentBase tab, owned Entity entity) {
		tab.model.append (entity);
		return true;
	}

	void append_results (Gee.ArrayList<Entity> array, Views.ContentBase tab) {
		if (!array.is_empty) {
			int all_i = 0;
			array.@foreach (e => {
				if (all_i < 4) {
					append_entity (all_tab, e);
					all_i++;
				}
				append_entity (tab, e);

				return true;
			});
		}
	}

	void request () {
		query = entry.text.chug ().chomp ();
		if (query == "") {
			clear ();
			base_status = new StatusMessage () { title = _("Enter Query") };
			return;
		}

		clear ();
		base_status = new StatusMessage () { loading = true };
		API.SearchResults.request.begin (query, accounts.active, (obj, res) => {
			try {
				var results = API.SearchResults.request.end (res);
				bool hashtag = query.has_prefix ("#");

				if (hashtag) append_results (results.hashtags, hashtags_tab);
				append_results (results.accounts, accounts_tab);
				if (!hashtag) append_results (results.hashtags, hashtags_tab);
				append_results (results.statuses, statuses_tab);

				base_status = new StatusMessage ();

				on_content_changed ();
			}
			catch (Error e) {
				on_error (-1, e.message);
			}
		});
	}

}
