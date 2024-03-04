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

            res.@foreach (e => {
                e.value.sort ((a, b) => a.shortcode.collate (b.shortcode));

                return true;
            });

		}

		return res;
	}

    ~CustomEmojiChooser () {
        debug ("Destroying CustomEmojiChooser");
    }

    private Gtk.Box custom_emojis_box;
    private Gtk.SearchEntry entry;
    private Gtk.FlowBox results;
    private Gtk.Label results_label;
    private Gtk.ScrolledWindow custom_emojis_scrolled;

    private Gtk.FlowBox recents;
    private Gtk.Label recents_label;

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

        recents_label = create_category_label (_("Recently Used"));
        recents_label.visible = false;
        custom_emojis_box.append (recents_label);

        recents = create_emoji_box ();
        recents.visible = false;
        custom_emojis_box.append (recents);

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
        entry.stop_search.connect (on_close);
    }

    private void add_to_results (API.Emoji emoji) {
        results.append (create_emoji_button (emoji));
    }

    private void remove_all_from_results () {
        results.remove_all ();
    }

    private void populate_recents () {
        recents.remove_all ();

        if (settings.recently_used_custom_emojis.length == 0) {
            recents.visible = false;
            recents_label.visible = false;
            return;
        }

        Gee.HashMap<string, API.Emoji> recents_to_api = new Gee.HashMap<string, API.Emoji> ();
        int total = settings.recently_used_custom_emojis.length;
        accounts.active.instance_emojis.@foreach (e => {
            if (!e.visible_in_picker) return true;

            if (e.shortcode in settings.recently_used_custom_emojis) {
                recents_to_api.set (e.shortcode, e);
                total -= 1;
            }

            if (total < 1) return false;

            return true;
        });

        for (int i = 0; i < settings.recently_used_custom_emojis.length; i++) {
            recents.append (create_emoji_button (recents_to_api.get (settings.recently_used_custom_emojis[i])));
        }

        recents.visible = true;
        recents_label.visible = true;
    }

    static int max_recents = 12;
    private void update_recents (string shortcode) {
        string[] res = {};
        res += shortcode;

        if (shortcode in settings.recently_used_custom_emojis) {
            foreach (var emoji in settings.recently_used_custom_emojis) {
                if (emoji != shortcode) res += emoji;
            }
        } else {
            // remove last one
            for (int i = 0; i < (settings.recently_used_custom_emojis.length < max_recents ? settings.recently_used_custom_emojis.length : max_recents - 1); i++) {
                res += settings.recently_used_custom_emojis[i];
            }
        }

        settings.recently_used_custom_emojis = res;
    }

    protected void search () {
        query = entry.text.chug ().chomp ().down ().replace (":", "");
        remove_all_from_results ();

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
                    add_to_results (e);
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
            update_recents (emoji.shortcode);
			emoji_picked (@":$(emoji.shortcode):");
		}
	}

    protected void on_close () {
        this.popdown ();
    }

    public override void show () {
        base.show ();

        GLib.Idle.add (() => {
            populate_recents ();
            if (!is_populated) populate_chooser ();
            entry.grab_focus ();
            return GLib.Source.REMOVE;
        });
    }

    protected void populate_chooser () {
        var categorized_custom_emojis = gen_emojis_cat_map ();
        var categories_keys = new Gee.ArrayList<string>.wrap (categorized_custom_emojis.keys.to_array ());
        categories_keys.sort ((a, b) => a.collate (b));

        if (categorized_custom_emojis.has_key (_("Other"))) {
            create_category (
                categorized_custom_emojis.size > 1
                    ? _("Other")
                    : _("Custom Emojis"),
                categorized_custom_emojis.get (_("Other"))
            );

            categories_keys.remove (_("Other"));
        }


        foreach (var t_shortcode in categories_keys) {
            create_category (
                t_shortcode,
                categorized_custom_emojis.get (t_shortcode)
            );
        };

        is_populated = true;
    }

    protected Gtk.Button create_emoji_button (API.Emoji emoji) {
        var emoji_btn = new Gtk.Button () {
            css_classes = { "flat", "picker-emoji-button" },
            child = new Widgets.Emoji (emoji.url, emoji.shortcode) { icon_size = Gtk.IconSize.LARGE }
        };

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
