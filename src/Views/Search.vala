using Gtk;

public class Tootle.Views.Search : Views.Base {

    private string query = "";
    private SearchBar bar;
    private SearchEntry entry;

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
    }

    private void append_account (API.Account acc) {
        var status = new API.Status.from_account (acc);
        var widget = new Widgets.Status (status);
        widget.button_press_event.connect (widget.on_avatar_clicked);
        content.pack_start (widget, false, false, 0);
        on_content_changed ();
    }

    private void append_status (API.Status status) {
        var widget = new Widgets.Status (status);
        widget.button_press_event.connect (widget.on_avatar_clicked);
        content.pack_start (widget, false, false, 0);
        on_content_changed ();
    }

    private void append_header (string name) {
        var widget = new Label (@"<span weight='bold' size='medium'>$name</span>");
        widget.halign = Align.START;
        widget.margin = 8;
        widget.use_markup = true;
        widget.show ();
        content.pack_start (widget, false, false, 0);
        on_content_changed ();
    }

    private void append_hashtag (string name) {
        var encoded = Soup.URI.encode (name, null);
        var widget = new Widgets.RichLabel (@"<a href=\"$(accounts.active.instance)/tags/$encoded\">#$name</a>");
        widget.use_markup = true;
        widget.halign = Align.START;
        widget.margin = 6;
        widget.margin_bottom = 0;
        widget.show ();
        content.pack_start (widget, false, false, 0);
    }

    private void request () {
        query = entry.text;
        if (query == "") {
            clear ();
            return;
        }

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
                        var obj = node.get_object ();
                        var acc = new API.Account (obj);
                        append_account (acc);
                    });
                }

                if (statuses.get_length () > 0) {
                    append_header (_("Statuses"));
                    statuses.foreach_element ((array, i, node) => {
                        var obj = node.get_object ();
                        var status = new API.Status (obj);
                        append_status (status);
                    });
                }
        	})
        	.on_error (on_error)
        	.exec ();
    }

}
