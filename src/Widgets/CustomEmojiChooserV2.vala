public class Tuba.Widgets.CustomEmojiChooserV2 : Gtk.Popover {
	const string RECENT_EMOJIS_CATEGORY = "tuba_recent_emojis_category";
	const int MAX_RECENTS = 12;

	public string query { get; set; default = ""; }
	public signal void emoji_picked (string shortcode);
	private bool search_active { get; set; default = false; }

	private Gee.HashMap<string, Gee.ArrayList<API.Emoji>>? instance_emoji_map = null;
	private Gee.HashMap<string, Gee.ArrayList<API.Emoji>> gen_emojis_cat_map () {
		var res = new Gee.HashMap<string, Gee.ArrayList<API.Emoji>> ();
		var emojis = accounts.active.instance_emojis;

		if (emojis != null && emojis.size > 0) {
			res.set (RECENT_EMOJIS_CATEGORY, new Gee.ArrayList<API.Emoji> ());
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

				if (e.shortcode in settings.recently_used_custom_emojis) {
					res.get (RECENT_EMOJIS_CATEGORY).add (e);
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

	~CustomEmojiChooserV2 () {
		debug ("Destroying CustomEmojiChooserV2");
		if (instance_emoji_map != null) instance_emoji_map.clear ();
	}

	private Gtk.SearchEntry entry;
	private Gtk.Stack main_stack;
	private GLib.ListStore cat_model;
	private GLib.ListStore moji_grid_model;
	private Gtk.Label cat_label;
	private Gtk.Box bottom_bar;
	private Gtk.StringFilter in_category_string_filter;

	// we need to construct it on demand as it can also be part of
	// reaction rows on statuses and we don't want them to go through
	// this for every single instance
	private bool has_been_constructed = false;
	private void initial_construct () {
		if (has_been_constructed) return;
		has_been_constructed = true;
		this.add_css_class ("emoji-picker");
		main_stack = new Gtk.Stack () {
			vexpand = true,
			hexpand = true,
			hhomogeneous = false,
			vhomogeneous = false
		};

		cat_model = new GLib.ListStore (typeof (EmojiCategory));
		var cat_listview = new Gtk.ListView (new Gtk.NoSelection (cat_model),
			new Gtk.BuilderListItemFactory.from_resource (
				null,
				@"$(Build.RESOURCES)gtk/dropdown/cep_main.ui"
			)
		) {
			single_click_activate = true,
			css_classes = { "cep-category" }
		};
		cat_listview.activate.connect (on_cat_activated);
		main_stack.add_named (new Gtk.ScrolledWindow () {
			hscrollbar_policy = Gtk.PolicyType.NEVER,
			height_request = 256,
			child = cat_listview
		}, "categories");

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		content_box.append (main_stack);
		this.child = content_box;

		moji_grid_model = new GLib.ListStore (typeof (API.Emoji));
		in_category_string_filter = new Gtk.StringFilter (
			new Gtk.PropertyExpression (typeof (API.Emoji), null, "shortcode")
		) { match_mode = Gtk.StringFilterMatchMode.SUBSTRING };
		var moji_grid = new Gtk.GridView (
			new Gtk.NoSelection (new Gtk.FilterListModel (moji_grid_model, in_category_string_filter)),
			new Gtk.BuilderListItemFactory.from_resource (
				null,
				@"$(Build.RESOURCES)gtk/dropdown/cep_emoji.ui"
			)
		) {
			single_click_activate = true,
			css_classes = { "cep-emoji" },
			max_columns = 6,
			min_columns = 6,
			margin_start = 6,
			margin_end = 6
		};
		moji_grid.activate.connect (on_emoji_picked);
		main_stack.add_named (new Gtk.ScrolledWindow () {
			hscrollbar_policy = Gtk.PolicyType.NEVER,
			height_request = 256,
			child = moji_grid
		}, "mojis");
		main_stack.notify["visible-child-name"].connect (on_stack_changed);

		bottom_bar = new Gtk.Box (HORIZONTAL, 6) {
			visible = false,
			margin_start = 6,
			margin_bottom = 6,
			margin_top = 6,
			margin_end = 6
		};

		var back_btn = new Gtk.Button.from_icon_name (is_rtl ? "tuba-right-large-symbolic" : "tuba-left-large-symbolic") {
			// translators: custom emoji chooser, back button tooltip text; clicking it
			//				takes you to the list of custom emoji categories
			tooltip_text = _("Categories"),
			css_classes = {"flat"}
		};
		back_btn.clicked.connect (on_back_clicked);
		cat_label = new Gtk.Label ("") {
			ellipsize = END,
			hexpand = true,
			css_classes = {"font-bold"}
		};
		bottom_bar.append (back_btn);
		bottom_bar.append (cat_label);
		content_box.append (bottom_bar);

		entry = new Gtk.SearchEntry () {
			text = query,
			hexpand = true,
			// real custom emoji
			placeholder_text = "boiled_skibidi_pizza…"
		};

		var entry_bin = new Adw.Bin () {
			css_classes = { "emoji-searchbar" },
			child = entry
		};
		content_box.prepend (entry_bin);

		entry.activate.connect (search);
		entry.search_changed.connect (search);
		entry.stop_search.connect (on_close);

		populate_chooser ();
	}

	private void update_recents (API.Emoji api_emoji) {
		string[] res = {};

		string shortcode = api_emoji.shortcode;
		res += shortcode;

		var recent_emojis_in_map = instance_emoji_map.get (RECENT_EMOJIS_CATEGORY);

		if (shortcode in settings.recently_used_custom_emojis) {
			foreach (var emoji in settings.recently_used_custom_emojis) {
				if (emoji != shortcode) res += emoji;
			}
			recent_emojis_in_map.remove (api_emoji);
		} else {
			// remove last one
			for (int i = 0; i < (settings.recently_used_custom_emojis.length < MAX_RECENTS ? settings.recently_used_custom_emojis.length : MAX_RECENTS - 1); i++) {
				res += settings.recently_used_custom_emojis[i];
			}

			if (settings.recently_used_custom_emojis.length >= MAX_RECENTS)
				recent_emojis_in_map.remove_at (recent_emojis_in_map.size - 1);
		}

		settings.recently_used_custom_emojis = res;
		recent_emojis_in_map.insert (0, api_emoji);
		setup_recents_emoji_category ();
		((EmojiCategory) ((ListModel) cat_model).get_item (0)).emoji_face = api_emoji;
	}

	private void search () {
		query = entry.text.chug ().chomp ().down ().replace (":", "");

		if (main_stack.visible_child_name == "categories") {
			setup_search ();
			this.search_active = true;
		}

		in_category_string_filter.search = query;

		if (query == "" && this.search_active) {
			main_stack.visible_child_name = "categories";
			this.search_active = false;
			return;
		}
	}

	private void on_custom_emoji_picked (API.Emoji emoji) {
		on_close ();
		update_recents (emoji);
		emoji_picked (@":$(emoji.shortcode): ");
	}

	private void on_close () {
		this.popdown ();
	}

	public override void show () {
		base.show ();
		if (!has_been_constructed) {
			initial_construct ();
		}
		entry.grab_focus ();
	}

	private void setup_recents_emoji_category () {
		if (
			settings.recently_used_custom_emojis.length == 0
			|| (
				cat_model.n_items > 0
				&& ((EmojiCategory) ((ListModel) cat_model).get_item (0)).real_category_name == RECENT_EMOJIS_CATEGORY
			)
		) return;

		cat_model.insert (0, new EmojiCategory () {
			name = _("Recently Used"),
			real_category_name = RECENT_EMOJIS_CATEGORY,
			emoji_face = instance_emoji_map.get (RECENT_EMOJIS_CATEGORY)[0]
		});
	}

	private void populate_chooser () {
		EmojiCategory[] cats = {};
		instance_emoji_map = gen_emojis_cat_map ();
		setup_recents_emoji_category ();

		var categories_keys = new Gee.ArrayList<string>.wrap (instance_emoji_map.keys.to_array ());
		categories_keys.remove (RECENT_EMOJIS_CATEGORY);
		categories_keys.sort (sort_strings);

		EmojiCategory? other_cat = null;
		if (instance_emoji_map.has_key (_("Other"))) {
			var mojis = instance_emoji_map.get (_("Other"));
			if (mojis.size > 0) {
				string cat_name = instance_emoji_map.size > 1
					? _("Other")
					: _("Custom Emojis");
				other_cat = new EmojiCategory () {
					name = cat_name,
					emoji_face = mojis[0],
					real_category_name = _("Other")
				};
				categories_keys.remove (_("Other"));
			}
		}


		foreach (var category in categories_keys) {
			cats += new EmojiCategory () {
				name = category,
				emoji_face = instance_emoji_map.get (category)[0],
				real_category_name = category
			};
		};

		if (other_cat != null) cats += other_cat;

		cat_model.splice (cat_model.n_items, 0, cats);
		categories_keys.clear ();
	}

	private int sort_strings (string a, string b) {
		return a.collate (b);
	}

	private void setup_search () {
		moji_grid_model.splice (
			0,
			moji_grid_model.n_items,
			accounts.active.instance_emojis.to_array ()
		);
		cat_label.label = _("Search");
		main_stack.visible_child_name = "mojis";
	}

	private void on_cat_activated (uint pos) {
		string category_name = ((EmojiCategory) ((ListModel) cat_model).get_item (pos)).real_category_name;
		moji_grid_model.splice (
			0,
			moji_grid_model.n_items,
			instance_emoji_map.get (category_name).to_array ()
		);
		cat_label.label = category_name == RECENT_EMOJIS_CATEGORY ? _("Recently Used") : category_name;
		main_stack.visible_child_name = "mojis";
		entry.grab_focus ();
		this.search_active = false;
	}

	private void on_emoji_picked (uint pos) {
		on_custom_emoji_picked ((API.Emoji) ((ListModel) moji_grid_model).get_item (pos));
	}

	private void on_stack_changed () {
		bottom_bar.visible = main_stack.visible_child_name != "categories";
	}

	private void on_back_clicked () {
		main_stack.visible_child_name = "categories";
		moji_grid_model.remove_all ();
		entry.grab_focus ();
		this.search_active = false;
	}

	public class EmojiCategory : GLib.Object {
		public string name { get; set; }
		public string emoji_shortcode { get; set; default = ""; }
		public string emoji_url { get; set; default = ""; }
		public string real_category_name { get; set; }

		public API.Emoji emoji_face {
			set {
				this.emoji_shortcode = value.shortcode;
				this.emoji_url = value.url;
			}
		}
	}
}
