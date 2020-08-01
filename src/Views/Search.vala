using Gtk;

public class Tootle.Views.Search : Views.Base {

	string query = "";
	SearchBar bar;
	SearchEntry entry;

	construct {
		label = _("Search");

		bar = new SearchBar ();
		bar.search_mode_enabled = true;
		bar.show ();
		pack_start (bar, false, false, 0);

		entry = new SearchEntry ();
		entry.width_chars = 25;
		entry.text = query;
		entry.show ();
		bar.add (entry);
		bar.connect_entry (entry);

		entry.activate.connect (() => request ());
		entry.icon_press.connect (() => request ());
		entry.grab_focus_without_selecting ();
		status_button.clicked.connect (request);

		request ();
	}

	bool append (owned Entity entity) {
		var w = entity.to_widget ();
		content_list.insert (w, -1);
		return true;
	}

	void append_header (string name) {
		var w = new Label (@"<span weight='bold' size='medium'>$name</span>");
		w.halign = Align.START;
		w.margin = 8;
		w.use_markup = true;
		w.show ();
		content_list.insert (w, -1);
	}

	void request () {
		query = entry.text.chug ().chomp ();
		if (query == "") {
			clear ();
			return;
		}

		clear ();
		status_message = STATUS_LOADING;
		API.SearchResults.request.begin (query, accounts.active, (obj, res) => {
			try {
				var results = API.SearchResults.request.end (res);

				if (!results.accounts.is_empty) {
					append_header (_("People"));
					results.accounts.@foreach (append);
				}

				if (!results.statuses.is_empty) {
					append_header (_("Posts"));
					results.statuses.@foreach (append);
				}

				if (!results.hashtags.is_empty) {
					append_header (_("Hashtags"));
					results.hashtags.@foreach (append);
				}

				on_content_changed ();
			}
			catch (Error e) {
				on_error (-1, e.message);
			}
		});
	}

}
