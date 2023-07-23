[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/widgets/bookwyrmpage.ui")]
public class Tuba.Widgets.BookWyrmPage : Gtk.Box {
    public API.BookWyrm book { get; private set; }

	[GtkChild] unowned Gtk.Picture cover;
	[GtkChild] unowned Gtk.Label title;
	[GtkChild] unowned Gtk.Label authors;
	[GtkChild] unowned Gtk.Label isbn;
	[GtkChild] unowned Gtk.Button ol_btn;
	[GtkChild] unowned Gtk.Label description;
	[GtkChild] unowned Gtk.Label date;

    // setting labels as selectable before they
    // are visible, causes them to be already
    // selected when they become visible
    public bool selectable {
        set {
            title.selectable =
            isbn.selectable =
            description.selectable =
                value;
        }
    }

    ~BookWyrmPage () {
		debug ("Destroying BookWyrmPage");
	}

    public BookWyrmPage (API.BookWyrm t_obj) {
        book = t_obj;
        title.label = t_obj.title;

        if (t_obj.cover != null && t_obj.cover.url != null && t_obj.cover.url != "") {
            image_cache.request_paintable (t_obj.cover.url, on_cache_response);

            if (t_obj.cover.name != "") {
                cover.alternative_text = cover.tooltip_text = t_obj.cover.name;
            }
        } else {
            cover.visible = false;
        }

        if (t_obj.authors != null && t_obj.authors.size > 0) {
            foreach (var author in t_obj.authors) {
                new Request.GET (@"$author.json")
                    .then ((sess, msg, in_stream) => {
                        var parser = Network.get_parser_from_inputstream (in_stream);
                        var node = network.parse_node (parser);
                        var author_obj = API.BookWyrmAuthor.from (node);
                        if (author_obj.id == author) {
                            authors.label = generate_authors_label (author_obj.name, author_obj.id);
                        }
                    })
                    .on_error (() => authors.visible = false)
                    .exec ();
            }
        } else {
            authors.visible = false;
        }

        if (t_obj.isbn13 != "") {
            isbn.label = @"ISBN: $(t_obj.isbn13)";
        } else {
            isbn.visible = false;
        }

        if (t_obj.openlibraryKey == "") {
            ol_btn.visible = false;
        }

        if (t_obj.description != "") {
            description.label = HtmlUtils.remove_tags (t_obj.description);
        } else {
            description.visible = false;
        }

        if (t_obj.publishedDate != "") {
            var date_parsed = new GLib.DateTime.from_iso8601 (t_obj.publishedDate, null);
            date_parsed = date_parsed.to_timezone (new TimeZone.local ());

            if (date_parsed != null) {
                // translators: the variable is the date the book was published
                date.label = _("Published: %s").printf (date_parsed.format ("%x"));
            } else {
                date.visible = false;
            }
        } else {
            date.visible = false;
        }
	}

    string authors_markup (string author, string? author_url = null) {
        if (author_url != null && author_url != "")
            return @"<a href=\"$author_url\">$author</a>";

        return author;
    }

    string[] author_labels = {};
    string generate_authors_label (string author, string? author_url = null) {
        author_labels += authors_markup (author, author_url);

        // translators: the variable is a comma separated
        //              list of the book authors
        return _("by %s").printf (string.joinv (", ", author_labels));
    }

	void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
        if (is_loaded)
            cover.paintable = data;
	}

    [GtkCallback]
    void open_on_openlibrary () {
        Host.open_uri (@"https://openlibrary.org/books/$(book.openlibraryKey)");
    }

    [GtkCallback]
    void open_on_bw () {
        Host.open_uri (book.id);
    }
}
