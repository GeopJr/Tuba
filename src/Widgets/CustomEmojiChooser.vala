public class Tuba.Widgets.CustomEmojiChooser : Gtk.Popover {
	public string query { get; set; default = ""; }
	public signal void emoji_picked (string shortcode);
	public bool is_populated { get; protected set; default=false; }

	private Gee.HashMap<string, Gee.ArrayList<API.Emoji>> gen_emojis_cat_map () {
		var res = new Gee.HashMap<string, Gee.ArrayList<API.Emoji>> ();
		var emojis = accounts.active.instance_emojis;

		if (emojis != null && emojis.size > 0) {
			emojis.foreach (e => {
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

			res.foreach (e => {
				e.value.sort (sort_emojis);

				return true;
			});
		}

		return res;
	}

	private int sort_emojis (API.Emoji a, API.Emoji b) {
		return a.shortcode.collate (b.shortcode);
	}

	~CustomEmojiChooser () {
		debug ("Destroying CustomEmojiChooser");
	}

	private Gtk.Box custom_emojis_box;
	private Gtk.SearchEntry entry;
	private Gtk.ScrolledWindow custom_emojis_scrolled;

	private EmojiCategory recents;
	private EmojiCategory results;
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

		results = new EmojiCategory (_("Results")) {
			visible = false
		};
		results.emoji_selected.connect (on_custom_emoji_picked);
		custom_emojis_box.append (results);

		recents = new EmojiCategory (_("Recently Used")) {
			visible = false
		};
		recents.emoji_selected.connect (on_custom_emoji_picked);
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

	private void populate_recents () {
		recents.remove_all ();

		if (settings.recently_used_custom_emojis.length == 0) {
			recents.visible = false;
			return;
		}

		Gee.HashMap<string, API.Emoji> recents_to_api = new Gee.HashMap<string, API.Emoji> ();
		int total = settings.recently_used_custom_emojis.length;
		accounts.active.instance_emojis.foreach (e => {
			if (!e.visible_in_picker) return true;

			if (e.shortcode in settings.recently_used_custom_emojis) {
				recents_to_api.set (e.shortcode, e);
				total -= 1;
			}

			if (total < 1) return false;

			return true;
		});

		for (int i = 0; i < settings.recently_used_custom_emojis.length; i++) {
			recents.add_emoji (recents_to_api.get (settings.recently_used_custom_emojis[i]));
		}

		recents_to_api.clear ();
		recents.visible = true;
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
		results.remove_all ();

		if (query == "") {
			results.visible = false;
			return;
		}

		var emojis = accounts.active.instance_emojis;
		if (emojis != null && emojis.size > 0) {
			var at_least_one = false;
			emojis.@foreach (e => {
				if (!e.visible_in_picker) return true;
				if (query in e.shortcode.down ()) {
					at_least_one = true;
					results.add_emoji (e);
				};

				return true;
			});

			if (at_least_one) {
				// translators: Used when there are results in the custom emoji picker
				results.label = _("Results");
				custom_emojis_scrolled.scroll_child (Gtk.ScrollType.START, false);
			} else {
				// translators: Used when there are 0 results in the custom emoji picker
				results.label = _("No Results");
			}

			results.visible = true;
		}
	}

	protected void on_custom_emoji_picked (string shortcode) {
		on_close ();
		update_recents (shortcode);
		emoji_picked (@":$shortcode: ");
	}

	protected void on_close () {
		this.popdown ();
	}

	public override void show () {
		base.show ();

		GLib.Idle.add (show_idle);
	}

	private bool show_idle () {
		populate_recents ();
		if (!is_populated) populate_chooser ();
		entry.grab_focus ();

		return GLib.Source.REMOVE;
	}

	protected void populate_chooser () {
		var categorized_custom_emojis = gen_emojis_cat_map ();
		var categories_keys = new Gee.ArrayList<string>.wrap (categorized_custom_emojis.keys.to_array ());
		categories_keys.sort (sort_strings);

		if (categorized_custom_emojis.has_key (_("Other"))) {
			string cat_name = categorized_custom_emojis.size > 1
				? _("Other")
				: _("Custom Emojis");
			var category = new EmojiCategory (cat_name);
			category.add_emojis (categorized_custom_emojis.get (_("Other")));
			category.emoji_selected.connect (on_custom_emoji_picked);

			custom_emojis_box.append (category);
			categories_keys.remove (_("Other"));
		}


		foreach (var t_shortcode in categories_keys) {
			var category = new EmojiCategory (t_shortcode);
			category.add_emojis (categorized_custom_emojis.get (t_shortcode));
			category.emoji_selected.connect (on_custom_emoji_picked);

			custom_emojis_box.append (category);
		};

		is_populated = true;
		categorized_custom_emojis.clear ();
		categories_keys.clear ();
	}

	private int sort_strings (string a, string b) {
		return a.collate (b);
	}

	class EmojiCategory : Gtk.Box {
		public signal void emoji_selected (string shortcode);

		class EmojiButton : Gtk.Button {
			public signal void emoji_selected (string shortcode);

			string shortcode;
			construct {
				this.css_classes = { "flat", "picker-emoji-button" };
			}

			public EmojiButton (API.Emoji emoji) {
				shortcode = emoji.shortcode;

				this.child = new Widgets.Emoji (emoji.url, emoji.shortcode) {
					icon_size = Gtk.IconSize.LARGE
				};
				this.clicked.connect (on_custom_emoji_picked);
			}

			private void on_custom_emoji_picked () {
				emoji_selected (shortcode);
			}
		}

		public string label {
			get { return title_label.label; }
			set { title_label.label = value; }
		}

		Gtk.Label title_label;
		Gtk.FlowBox emoji_box;
		construct {
			this.orientation = Gtk.Orientation.VERTICAL;
			this.spacing = 6;

			title_label = new Gtk.Label ("") {
				wrap = true,
				wrap_mode = Pango.WrapMode.WORD_CHAR,
				halign = Gtk.Align.START,
				margin_top = 3
			};

			emoji_box = new Gtk.FlowBox () {
				homogeneous = true,
				column_spacing = 6,
				row_spacing = 6,
				max_children_per_line = 6,
				min_children_per_line = 6,
				selection_mode = Gtk.SelectionMode.NONE
			};

			this.append (title_label);
			this.append (emoji_box);
		}

		public EmojiCategory (string title) {
			title_label.label = title;
		}

		public void add_emojis (Gee.ArrayList<API.Emoji> emojis) {
			emojis.foreach (add_emoji);
		}

		public bool add_emoji (owned API.Emoji emoji) {
			var emoji_btn = new EmojiButton (emoji);
			emoji_btn.emoji_selected.connect (on_custom_emoji_picked);

			emoji_box.append (new Gtk.FlowBoxChild () {
				child = emoji_btn,
				focusable = false
			});

			return true;
		}

		public void remove_all () {
			emoji_box.remove_all ();
		}

		private void on_custom_emoji_picked (string shortcode) {
			emoji_selected (shortcode);
		}
	}
}
