public class Tuba.Widgets.CustomEmojiChooser : Gtk.Popover {
	public string query { get; set; default = ""; }
    public signal void emoji_picked (string shortcode);
    public bool is_populated { get; protected set; default=false; }

    private Gee.HashMap<string, Gee.ArrayList<API.Emoji>> gen_emojis_cat_map () {
		var res = new Gee.HashMap<string, Gee.ArrayList<API.Emoji>> ();
		var emojis = accounts.active.instance_emojis;

		if (emojis != null && emojis.size > 0) {
			emojis.@foreach (e => {
				if (!e.visible_in_picker) return true;

				if (res.has_key (e.category)) {
					var array = res.get (e.category);
					array.add (e);
				} else {
					var array = new Gee.ArrayList<API.Emoji> ();
					array.add (e);
					res.set (e.category, array);
				}

				return true;
			});
		}

		return res;
	}

    private Gtk.Box custom_emojis_box;
    private Gtk.SearchEntry entry;
    private Gtk.FlowBox results;
    private Gtk.Label results_label;
    private Gtk.ScrolledWindow custom_emojis_scrolled;
    private GLib.ListStore list_store = new GLib.ListStore (typeof (API.Emoji));
	construct {
        this.add_css_class ("emoji-picker");
        custom_emojis_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 6) {
            margin_end = 6,
            margin_bottom = 6,
            margin_start = 6
        };
		custom_emojis_scrolled = new Gtk.ScrolledWindow () {
			hscrollbar_policy = Gtk.PolicyType.NEVER,
			height_request = 360
		};
        var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content_box.append (custom_emojis_scrolled);

        this.child = content_box;
		custom_emojis_scrolled.child = custom_emojis_box;

        results_label = create_category_label (_("Results"));
        results_label.visible = false;
        custom_emojis_box.append (results_label);

        results = create_emoji_box ();
        custom_emojis_box.append (results);

        results.bind_model (list_store, model => {
            var emoji = model as API.Emoji;
            if (emoji == null) Process.exit (0);
            return create_emoji_button (emoji);
        });

        entry = new Gtk.SearchEntry () {
			text = query,
            hexpand = true
		};

        var entry_bin = new Adw.Bin () {
            css_classes = { "emoji-searchbar" },
            child = entry
        };
		content_box.prepend (entry_bin);

        entry.activate.connect (search);
        entry.search_changed.connect (search);
        entry.stop_search.connect (search);
    }

    protected void search () {
        query = entry.text.chug ().chomp ().down ().replace (":", "");
        list_store.remove_all ();

		if (query == "") {
            results_label.visible = false;
			return;
		}

        var emojis = accounts.active.instance_emojis;

		if (emojis != null && emojis.size > 0) {
            var at_least_one = false;
			emojis.@foreach (e => {
				if (!e.visible_in_picker) return true;
				if (query in e.shortcode) {
                    at_least_one = true;
                    list_store.append (e);
                };

				return true;
			});

            if (at_least_one) {
                // translators: Used when there are results in the custom emoji picker
                results_label.label = _("Results");
                custom_emojis_scrolled.scroll_child (Gtk.ScrollType.START, false);
            } else {
                // translators: Used when there are 0 results in the custom emoji picker
                results_label.label = _("No Results");
            }

            results_label.visible = true;
		}
    }

    protected void on_custom_emoji_picked (Gtk.Button emoji_btn) {
		var emoji = emoji_btn.child as Emoji;
		if (emoji != null) {
            on_close ();
			emoji_picked (@":$(emoji.shortcode):");
		}
	}

    protected void on_close () {
        this.popdown ();
    }

    public override void show () {
        base.show ();

        GLib.Idle.add (() => {
            if (!is_populated) populate_chooser ();
            entry.grab_focus ();
            return GLib.Source.REMOVE;
        });
    }

    protected void populate_chooser () {
        var categorized_custom_emojis = gen_emojis_cat_map ();

        categorized_custom_emojis.@foreach (e => {
            if (e.key == _("Other")) return true;
			create_category (e.key, e.value);

			return true;
		});

        if (categorized_custom_emojis.has_key (_("Other")))
            create_category (
                categorized_custom_emojis.size > 1
                    ? _("Other")
                    : _("Custom Emojis"),
                categorized_custom_emojis.get (_("Other"))
            );

        is_populated = true;
    }

    protected Gtk.Button create_emoji_button (API.Emoji emoji) {
        var emoji_btn = new Gtk.Button () {
            css_classes = { "flat" },
            child = new Widgets.Emoji (emoji.url, emoji.shortcode)
        };
        emoji_btn.set_css_name ("emoji");

        emoji_btn.clicked.connect (on_custom_emoji_picked);
        return emoji_btn;
    }

    protected void create_category (string key, Gee.ArrayList<API.Emoji> value) {
        custom_emojis_box.append (create_category_label (key));

        var emojis_flowbox = create_emoji_box ();
        value.@foreach (emoji => {
            emojis_flowbox.append (create_emoji_button (emoji));

            return true;
        });

        custom_emojis_box.append (emojis_flowbox);
    }

    protected Gtk.FlowBox create_emoji_box () {
        return new Gtk.FlowBox () {
            homogeneous = true,
            column_spacing = 6,
            row_spacing = 6,
            max_children_per_line = 6,
            min_children_per_line = 6,
            selection_mode = Gtk.SelectionMode.NONE
        };
    }

    protected Gtk.Label create_category_label (string label) {
        return new Gtk.Label (label) {
            wrap = true,
            wrap_mode = Pango.WrapMode.WORD_CHAR,
            halign = Gtk.Align.START,
            margin_top = 3
        };
    }
}
