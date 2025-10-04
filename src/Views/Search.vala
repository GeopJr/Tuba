public class Tuba.Views.Search : Views.TabbedBase {
	public class SearchEntry : Gtk.Box {
		public signal void on_advanced_search_clicked ();
		public signal void on_entry_activate ();

		public string text {
			get { return entry.text; }
			set { entry.text = value; }
		}
		public Gtk.Text entry { get; private set; }

		static construct {
			set_css_name ("entry");
		 }

		Gtk.Button clear_search_button;
		construct {
			this.spacing = 9;
			this.orientation = Gtk.Orientation.HORIZONTAL;
			this.css_classes = {"search", "rounded"};

			entry = new Gtk.Text () {
				width_chars = 25,
				placeholder_text = _("Search Posts and Accounts"),
				hexpand = true
			};
			entry.changed.connect (on_entry_change);
			entry.activate.connect (on_entry_activated);

			var advanced_search = new Gtk.Button.from_icon_name ("tuba-funnel-symbolic") {
				tooltip_text = _("Advanced Search"),
				css_classes = {"flat", "circular", "entry-button"},
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};

			clear_search_button = new Gtk.Button.from_icon_name ("edit-clear-symbolic") {
				tooltip_text = _("Clear Entry"),
				css_classes = {"flat", "circular", "entry-button"},
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER
			};
			on_entry_change ();

			advanced_search.clicked.connect (open_advanced_search_dialog);
			clear_search_button.clicked.connect (on_clear_entry);

			this.append (new Gtk.Image.from_icon_name ("tuba-loupe-large-symbolic"));
			this.append (entry);
			this.append (clear_search_button);
			this.append (advanced_search);
		}

		public void gather_focus () {
			entry.grab_focus ();
		}

		private void on_entry_activated () {
			on_entry_activate ();
		}

		private void open_advanced_search_dialog () {
			on_advanced_search_clicked ();
		}

		private void on_clear_entry () {
			entry.text = "";
		}

		private void on_entry_change () {
			bool can_clear = entry.text != "";

			clear_search_button.can_target =
			clear_search_button.sensitive = can_clear;
			clear_search_button.opacity = can_clear ? 1.0f : 0.0f;
		}
	}

	public string query { get; set; default = ""; }
	protected Gtk.SearchBar bar;
	protected SearchEntry entry;

	Views.ContentBase all_tab;
	Views.ContentBase accounts_tab;
	Views.ContentBase statuses_tab;
	Views.ContentBase hashtags_tab;

	construct {
		this.uid = 1;

		label = _("Search");
		this.empty_timeline_icon = "system-search";
		this.empty_state_title = _("Search");

		bar = new Gtk.SearchBar () {
			search_mode_enabled = true
		};
		toolbar_view.add_top_bar (bar);

		entry = new SearchEntry ();
		entry.on_advanced_search_clicked.connect (open_advanced_search_dialog);

		bar.child = new Adw.Clamp () {
			child = entry,
			maximum_size = 300
		};
		bar.connect_entry (entry.entry);

		entry.on_entry_activate.connect (request);
		status_button.clicked.connect (request);

		// translators: as in All search results
		all_tab = add_list_tab (_("All"), "tuba-loupe-large-symbolic", _("No Results"));
		accounts_tab = add_list_tab (_("Accounts"), "tuba-people-symbolic", _("No Results"));
		statuses_tab = add_list_tab (_("Posts"), "tuba-chat-symbolic", _("No Results"));
		hashtags_tab = add_list_tab (_("Hashtags"), "tuba-hashtag-symbolic", _("No Results"));

		uint timeout = 0;
		timeout = Timeout.add (200, () => {
			entry.gather_focus ();
			GLib.Source.remove (timeout);

			return true;
		}, Priority.LOW);

		request ();
	}

	bool append_entity (Views.ContentBase tab, owned Entity entity) {
		API.SearchResult search_result_entity = entity as API.SearchResult;
		if (search_result_entity != null) {
			search_result_entity.tuba_search_query_regex = search_query_regex;
		}
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

	// TODO: replace all actionsrow widgetizables with this
	public class OpenableRow : Adw.ActionRow {
		public signal void open ();
	}

	public class SearchHistoryRow : Entity, Widgetizable {
		public string title { get; set; }
		public signal void remove_me (string title);
		public signal void open_me (string title);

		public SearchHistoryRow (string title) {
			this.title = title;
		}

		public override Gtk.Widget to_widget () {
			var row = new OpenableRow () {
				title = this.title,
				use_markup = false,
				activatable = true
			};
			row.open.connect (open);

			var remove_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
				tooltip_text = _("Remove"),
				valign = Gtk.Align.CENTER,
				halign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular", "error" }
			};
			remove_btn.clicked.connect (on_remove_me);

			row.add_suffix (remove_btn);

			return row;
		}

		private void open () {
			open_me (this.title);
		}

		private void on_remove_me () {
			remove_me (this.title);
		}
	}

	private bool populate_with_recents () {
		if (settings.recent_searches.length == 0) return false;

		foreach (var recent_query in settings.recent_searches) {
			var row = new SearchHistoryRow (recent_query);
			row.open_me.connect (on_asd_result);
			row.remove_me.connect (on_remove_recent);

			append_entity (all_tab, row);
		}

		return true;
	}

	void request () {
		this.query = entry.text.chug ().chomp ();
		if (this.query == "") {
			clear ();
			base_status = populate_with_recents () ? null : new StatusMessage ();
			return;
		}

		clear ();
		base_status = new StatusMessage () { loading = true };
		generate_regex ();
		API.SearchResults.request.begin (query, accounts.active, (obj, res) => {
			try {
				var results = API.SearchResults.request.end (res);
				bool hashtag = query.has_prefix ("#");

				if (hashtag) append_results (results.hashtags, hashtags_tab);
				append_results (results.accounts, accounts_tab);
				if (!hashtag) append_results (results.hashtags, hashtags_tab);
				append_results (results.statuses, statuses_tab);

				update_recents (query);
				base_status = new StatusMessage ();

				on_content_changed ();
			} catch (Error e) {
				on_error (-1, e.message);
			}
		});
	}

	const int MAX_RECENTS = 12;
	private void update_recents (string query) {
		string[] res = {query};

		if (query in settings.recent_searches) {
			foreach (var old_query in settings.recent_searches) {
				if (old_query != query) res += old_query;
			}
		} else {
			// remove last one
			for (int i = 0; i < (settings.recent_searches.length < MAX_RECENTS ? settings.recent_searches.length : MAX_RECENTS - 1); i++) {
				res += settings.recent_searches[i];
			}
		}

		settings.recent_searches = res;
	}

	private void on_remove_recent (SearchHistoryRow row, string query) {
		string[] res = {};

		foreach (var old_query in settings.recent_searches) {
			if (old_query != query) res += old_query;
		}

		settings.recent_searches = res;

		uint indx;
		if (all_tab.model.find (row, out indx)) all_tab.model.remove (indx);
		if (all_tab.model.get_n_items () == 0) base_status = new StatusMessage ();
	}

	GLib.Regex? search_query_regex = null;
	private void generate_regex () {
		if (this.query.length >= 45) return;

		try {
			search_query_regex = new Regex (
				// "this is a test." => /(:?\bthis\b:?|:?\bis\b:?|:?\ba\b:?|:?\btest\.\b:?)/
				@"(:?\\b$(GLib.Regex.escape_string (this.query).replace (" ", "\\b:?|:?\\b"))\\b:?)",
				GLib.RegexCompileFlags.CASELESS | GLib.RegexCompileFlags.OPTIMIZE
			);
		} catch (RegexError e) {
			warning (@"Error generating search query regex from \"$(this.query)\": $(e.message)");
		}
	}

	private void open_advanced_search_dialog () {
		var asd = new AdvancedSearchDialog (entry.text);
		asd.result.connect (on_asd_result);

		asd.present (app.main_window);
	}

	private void on_asd_result (string result) {
		entry.text = result;
		request ();
	}

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/advanced_search.ui")]
	private class AdvancedSearchDialog : Adw.Dialog {
		[GtkChild] unowned Gtk.ListBox main_list;

		[GtkChild] unowned Adw.ToastOverlay toast_overlay;
		[GtkChild] unowned Adw.EntryRow query_row;
		[GtkChild] unowned Adw.EntryRow user_row;
		[GtkChild] unowned Gtk.Button auto_fill_users_button;
		[GtkChild] unowned Adw.SwitchRow reply_switch_row;
		[GtkChild] unowned Adw.SwitchRow cw_switch_row;

		[GtkChild] unowned Adw.SwitchRow media_switch_row;
		[GtkChild] unowned Adw.SwitchRow poll_switch_row;
		[GtkChild] unowned Adw.SwitchRow embed_switch_row;

		[GtkChild] unowned Gtk.CheckButton all_radio;
		[GtkChild] unowned Gtk.CheckButton library_radio;
		[GtkChild] unowned Gtk.CheckButton public_radio;

		[GtkChild] unowned Adw.ExpanderRow before_expander_row;
		[GtkChild] unowned Gtk.Calendar before_calendar;
		[GtkChild] unowned Adw.ExpanderRow during_expander_row;
		[GtkChild] unowned Gtk.Calendar during_calendar;
		[GtkChild] unowned Adw.ExpanderRow after_expander_row;
		[GtkChild] unowned Gtk.Calendar after_calendar;

		~AdvancedSearchDialog () {
			debug ("Destroying AdvancedSearchDialog");
		}

		public signal void result (string res);

		private Gtk.DropDown lang_dropdown;
		private Gtk.Switch lang_switch;
		construct {
			before_calendar.remove_css_class ("view");
			during_calendar.remove_css_class ("view");
			after_calendar.remove_css_class ("view");

			var lang_row = new Adw.ActionRow () {
				title = _("Language")
			};
			main_list.append (lang_row);

			lang_switch = new Gtk.Switch () {
				valign = Gtk.Align.CENTER
			};

			lang_dropdown = new Gtk.DropDown (app.app_locales.list_store, null) {
				expression = new Gtk.PropertyExpression (typeof (Utils.Locales.Locale), null, "en-name"),
				factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language_title.ui"),
				list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/language.ui"),
				enable_search = true,
				valign = Gtk.Align.CENTER,
				sensitive = false
			};

			lang_row.add_suffix (lang_switch);
			lang_row.add_suffix (lang_dropdown);

			lang_switch.bind_property ("active", lang_dropdown, "sensitive", GLib.BindingFlags.SYNC_CREATE);
		}

		public AdvancedSearchDialog (string? from_query = null) {
			if (from_query != null && from_query != "") {
				string[] clean_query = {};
				var words = from_query.split (" ");
				foreach (string word in words) {
					string down_word = word.down ();
					switch (down_word) {
						case "is:reply":
							reply_switch_row.active = true;
							break;
						case "is:sensitive":
							cw_switch_row.active = true;
							break;
						case "has:media":
							media_switch_row.active = true;
							break;
						case "has:poll":
							poll_switch_row.active = true;
							break;
						case "has:embed":
							embed_switch_row.active = true;
							break;
						case "in:all":
							all_radio.active = true;
							break;
						case "in:library":
							library_radio.active = true;
							break;
						case "in:public":
							public_radio.active = true;
							break;
						default:
							if (down_word.has_prefix ("from:")) {
								string from_str = word.splice (0, 5);
								if (from_str[0] == '@') from_str = from_str.splice (0, 1);

								user_row.text = from_str;
							} else if (down_word.has_prefix ("language:")) {
								string locale_str = down_word.splice (0, 9);

								uint default_lang_index;
								if (
									app.app_locales.list_store.find_with_equal_func (
										new Utils.Locales.Locale (locale_str, null, null),
										Utils.Locales.Locale.compare,
										out default_lang_index
									)
								) {
									lang_switch.active = true;
									lang_dropdown.selected = default_lang_index;
								}
							} else if (down_word.has_prefix ("before:")) {
								string before_str = down_word.splice (0, 7);
								var date_split = before_str.split ("-");

								if (date_split.length == 3) {
									int year = int.parse (date_split[0]);
									int month = int.parse (date_split[1]) - 1;
									int day = int.parse (date_split[2]);

									if (year > 0 && month > 0 && day > 0) {
										before_expander_row.expanded = true;

										#if GTK_4_20_0
											before_calendar.date = new GLib.DateTime.utc (
												year,
												month,
												day,
												0, 0 ,0
											);
										#else
											before_calendar.year = year;
											before_calendar.month = month;
											before_calendar.day = day;
										#endif
									}
								}
							} else if (down_word.has_prefix ("during:")) {
								string during_str = down_word.splice (0, 7);
								var date_split = during_str.split ("-");
								if (date_split.length == 3) {
									int year = int.parse (date_split[0]);
									int month = int.parse (date_split[1]) - 1;
									int day = int.parse (date_split[2]);

									if (year > 0 && month > 0 && day > 0) {
										during_expander_row.expanded = true;

										#if GTK_4_20_0
											during_calendar.date = new GLib.DateTime.utc (
												year,
												month,
												day,
												0, 0 ,0
											);
										#else
											during_calendar.year = year;
											during_calendar.month = month;
											during_calendar.day = day;
										#endif
									}
								}
							} else if (down_word.has_prefix ("after:")) {
								string after_str = down_word.splice (0, 6);
								var date_split = after_str.split ("-");
								if (date_split.length == 3) {
									int year = int.parse (date_split[0]);
									int month = int.parse (date_split[1]) - 1;
									int day = int.parse (date_split[2]);

									if (year > 0 && month > 0 && day > 0) {
										after_expander_row.expanded = true;

										#if GTK_4_20_0
											after_calendar.date = new GLib.DateTime.utc (
												year,
												month,
												day,
												0, 0 ,0
											);
										#else
											after_calendar.year = year;
											after_calendar.month = month;
											after_calendar.day = day;
										#endif
									}
								}
							} else {
								clean_query += word;
							}
							break;
					}

					query_row.text = string.joinv (" ", clean_query);
				}
			}
		}

		[GtkCallback] void on_user_row_changed () {
			auto_fill_users_button.visible = user_row.text.length > 0;
		}

		[GtkCallback] void on_search_users_clicked () {
			string user_query = user_row.text.chug ().chomp ();
			if (user_query == "") return;

			auto_fill_users_button.sensitive = false;
			new Request.GET ("/api/v2/search")
				.with_account (accounts.active)
				.with_param ("q", user_query)
				.with_param ("type", "accounts")
				.with_param ("exclude_unreviewed", "true")
				.with_param ("limit", "1")
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					var search_results = API.SearchResults.from (network.parse_node (parser));

					if (search_results.accounts.size > 0) {
						user_row.text = search_results.accounts.get (0).full_handle;
					}

					auto_fill_users_button.sensitive = true;
				})
				.on_error ((code, message) => {
					auto_fill_users_button.sensitive = true;
					// translators: warning toast in advanced search dialog when auto-filling a user fails.
					// 				Auto-fill refers to automatically filling the entry with the first
					//				found user based on the query.
					toast_overlay.add_toast (new Adw.Toast (_("Couldn't auto-fill user: %s").printf (message)) {
						timeout = 5
					});

					warning (@"Couldn't auto-fill user with $user_query: $code $message");
				})
				.exec ();
		}

		[GtkCallback] void on_search () {
			string final_query = query_row.text;
			string[] props = {};

			if (user_row.text != "") {
				var from_str = user_row.text.replace (" ", "");
				if (from_str[0] == '@') from_str = from_str.splice (0, 1);

				props += @"from:$from_str";
			}

			if (reply_switch_row.active) props += "is:reply";
			if (cw_switch_row.active) props += "is:sensitive";

			if (media_switch_row.active) props += "has:media";
			if (poll_switch_row.active) props += "has:poll";
			if (embed_switch_row.active) props += "has:embed";

			if (all_radio.active) {
				props += "in:all";
			} else if (library_radio.active) {
				props += "in:library";
			} else if (public_radio.active) {
				props += "in:public";
			}

			if (before_expander_row.expanded) {
				props += @"before:$(before_calendar.get_date ().format ("%F"))";
			}

			if (during_expander_row.expanded) {
				props += @"during:$(during_calendar.get_date ().format ("%F"))";
			}

			if (after_expander_row.expanded) {
				props += @"after:$(after_calendar.get_date ().format ("%F"))";
			}

			if (lang_dropdown.sensitive) {
				props += @"language:$(((Utils.Locales.Locale) lang_dropdown.selected_item).locale)";
			}

			result (@"$final_query $(string.joinv (" ", props))");
			on_exit ();
		}

		[GtkCallback] void on_exit () {
			this.force_close ();
		}
	}
}
