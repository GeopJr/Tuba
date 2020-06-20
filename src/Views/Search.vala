using Gtk;

public class Tootle.Views.Search : Views.Base {

    string query = "";
    SearchBar bar;
    SearchEntry entry;

    construct {
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

    void append_account (API.Account acc) {
        var status = new API.Status.from_account (acc);
        var w = new Widgets.Status (status);
        w.button_press_event.connect (w.on_avatar_clicked);
        content_list.insert (w, -1);
        on_content_changed ();
    }

    void append_status (API.Status status) {
        var w = new Widgets.Status (status);
        w.button_press_event.connect (w.on_avatar_clicked);
        content_list.insert (w, -1);
        on_content_changed ();
    }

    void append_header (string name) {
        var w = new Label (@"<span weight='bold' size='medium'>$name</span>");
        w.halign = Align.START;
        w.margin = 8;
        w.use_markup = true;
        w.show ();
        content_list.insert (w, -1);
        on_content_changed ();
    }

    void append_hashtag (string name) {
        var encoded = Soup.URI.encode (name, null);
        var w = new Widgets.RichLabel (@"<a href=\"$(accounts.active.instance)/tags/$encoded\">#$name</a>");
        w.use_markup = true;
        w.halign = Align.START;
        w.margin = 8;
        w.show ();
        content_list.insert (w, -1);
    }

    void request () {
        query = entry.text;
        if (query == "") {
            clear ();
            return;
        }

        status_message = STATUS_LOADING;
        new Request.GET ("/api/v2/search")
        	.with_account (accounts.active)
        	.with_param ("resolve", "true")
        	.with_param ("q", Soup.URI.encode (query, null))
        	.then ((sess, msg) => {
                var root = network.parse (msg);
                var accounts = root.get_array_member ("accounts");
                var statuses = root.get_array_member ("statuses");
                var hashtags = root.get_array_member ("hashtags");

                clear ();

                if (hashtags.get_length () > 0) {
                    append_header (_("Hashtags"));
                    hashtags.foreach_element ((array, i, node) => {
                        append_hashtag (node.get_object ().get_string_member ("name"));
                    });
                }

                if (accounts.get_length () > 0) {
                    append_header (_("Accounts"));
                    accounts.foreach_element ((array, i, node) => {
                        var acc = API.Account.from (node);
                        append_account (acc);
                    });
                }

                if (statuses.get_length () > 0) {
                    append_header (_("Statuses"));
                    statuses.foreach_element ((array, i, node) => {
                        var status = API.Status.from (node);
                        append_status (status);
                    });
                }
        	})
        	.on_error (on_error)
        	.exec ();
    }

}
