public class Tuba.Widgets.BookWyrmPage : Gtk.Box {
    public API.BookWyrm book { get; private set; }
    private Gtk.Picture cover;

    // setting labels as selectable before they
    // are visible, causes them to be already
    // selected when they become visible
    private Gtk.Label [] selectable_labels = {};
    public bool selectable {
        set {
            foreach (var label in selectable_labels) {
                label.selectable = value;
            }
        }
    }

	construct {
		orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;
        margin_bottom = 12;
        cover = new Gtk.Picture () {
            height_request = 200,
            css_classes = { "attachment-picture" }
        };

        #if GTK_4_8
            cover.set_property ("content-fit", 2);
		#endif
	}
    ~BookWyrmPage () {
		message ("Destroying BookWyrmPage");
        selectable_labels = {};
	}

    public BookWyrmPage (API.BookWyrm t_obj) {
        book = t_obj;

        var header_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 32);
        if (t_obj.cover != null && t_obj.cover.url != null && t_obj.cover.url != "") {
            header_box.append (cover);
            image_cache.request_paintable (t_obj.cover.url, on_cache_response);

            if (t_obj.cover.name != "") {
                cover.alternative_text = cover.tooltip_text = t_obj.cover.name;
            }
        }

        var title_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            valign = Gtk.Align.CENTER,
            hexpand = true
        };
        var book_title = new Gtk.Label (t_obj.title) {
            wrap = true,
            css_classes = { "title-1" },
            halign = Gtk.Align.START
        };
        selectable_labels += book_title;
        title_box.append (book_title);

        if (t_obj.authors != null && t_obj.authors.size > 0) {
            Gtk.Label author_label = new Gtk.Label ("") {
                wrap = true,
                use_markup = true,
                halign = Gtk.Align.START
            };
            title_box.insert_child_after (author_label, book_title);

            foreach (var author in t_obj.authors) {
                new Request.GET (@"$author.json")
                    .then ((sess, msg, in_stream) => {
                        var parser = Network.get_parser_from_inputstream(in_stream);
                        var node = network.parse_node (parser);
                        var author_obj = API.BookWyrmAuthor.from (node);
                        if (author_obj.id == author) {
                            author_label.label = generate_authors_label (author_obj.name, author_obj.id);
                        }
                    })
                    .exec ();
            }
        }

        if (t_obj.isbn13 != "") {
            var isbn_label = new Gtk.Label (@"ISBN: $(t_obj.isbn13)") {
                wrap=true,
                halign = Gtk.Align.START
            };
            selectable_labels += isbn_label;
            title_box.append (isbn_label);
        }

        header_box.append (title_box);
        append (header_box);

        var btn_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12);

        var bw_btn = new Gtk.Button.with_label("BookWyrm");
        bw_btn.clicked.connect (open_on_bw);
        btn_box.append (bw_btn);

        if (t_obj.openlibraryKey != "") {
            var ol_btn = new Gtk.Button.with_label("OpenLibrary");
            ol_btn.clicked.connect (open_on_openlibrary);
            btn_box.append (ol_btn);
        }

        append (btn_box);

        if (t_obj.description != "") {
            var description_label = new Gtk.Label (HtmlUtils.remove_tags (t_obj.description)) {
                wrap = true,
                css_classes = { "card", "bkwm-desc" }
            };
            selectable_labels += description_label;
            append (description_label);
        }

        if (t_obj.publishedDate != "") {
            var date_parsed = new GLib.DateTime.from_iso8601 (t_obj.publishedDate, null);
            date_parsed = date_parsed.to_timezone (new TimeZone.local ());

            if (date_parsed != null)
                append (new Gtk.Label (@"Published: $(date_parsed.format("%x"))") { wrap=true });
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
		cover.paintable = data;
	}

    void open_on_openlibrary () {
        Host.open_uri (@"https://openlibrary.org/books/$(book.openlibraryKey)");
    }

    void open_on_bw () {
        Host.open_uri (book.id);
    }
}
