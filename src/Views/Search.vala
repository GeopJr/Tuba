public class Tuba.Views.Search : Views.TabbedBase {

	public string query { get; set; default = ""; }
	protected Gtk.SearchBar bar;
	protected Adw.Clamp bar_clamp;
	protected Gtk.SearchEntry entry;

	Views.ContentBase all_tab;
	Views.ContentBase accounts_tab;
	Views.ContentBase statuses_tab;
	Views.ContentBase hashtags_tab;

	construct {
		label = _("Search");

		bar = new Gtk.SearchBar () {
			search_mode_enabled = true
		};
		toolbar_view.add_top_bar (bar);

		entry = new Gtk.SearchEntry () {
			width_chars = 25,
			text = query,
			placeholder_text = _("Enter Query")
		};

		var advanced_search = new Gtk.Button.from_icon_name ("tuba-lightbulb-symbolic") {
			css_classes = {"flat"},
			tooltip_text = _("Advanced Search")
		};
		advanced_search.clicked.connect (open_advanced_search_dialog);

		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
		box.append (advanced_search);
		box.append (entry);

		bar_clamp = new Adw.Clamp () {
			child = box
		};

		bar.child = bar_clamp;
		bar.connect_entry (entry);

		entry.activate.connect (request);
		status_button.clicked.connect (request);

		// translators: as in All search results
		all_tab = add_list_tab (_("All"), "tuba-loupe-large-symbolic", _("No Results"));
		accounts_tab = add_list_tab (_("Accounts"), "tuba-people-symbolic", _("No Results"));
		statuses_tab = add_list_tab (_("Posts"), "tuba-chat-symbolic", _("No Results"));
		hashtags_tab = add_list_tab (_("Hashtags"), "tuba-hashtag-symbolic", _("No Results"));

		uint timeout = 0;
		timeout = Timeout.add (200, () => {
			entry.grab_focus ();
			GLib.Source.remove (timeout);

			return true;
		}, Priority.LOW);

		request ();
	}

	bool append_entity (Views.ContentBase tab, owned Entity entity) {
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

	void request () {
		query = entry.text.chug ().chomp ();
		if (query == "") {
			clear ();
			base_status = new StatusMessage () { title = _("Enter Query") };
			return;
		}

		clear ();
		base_status = new StatusMessage () { loading = true };
		API.SearchResults.request.begin (query, accounts.active, (obj, res) => {
			try {
				var results = API.SearchResults.request.end (res);
				bool hashtag = query.has_prefix ("#");

				if (hashtag) append_results (results.hashtags, hashtags_tab);
				append_results (results.accounts, accounts_tab);
				if (!hashtag) append_results (results.hashtags, hashtags_tab);
				append_results (results.statuses, statuses_tab);

				base_status = new StatusMessage ();

				on_content_changed ();
			}
			catch (Error e) {
				on_error (-1, e.message);
			}
		});
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

		[GtkChild] unowned Adw.EntryRow query_row;
		[GtkChild] unowned Adw.EntryRow user_row;
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
			var lang_row = new Adw.ActionRow () {
				title = _("Language")
			};
			main_list.append (lang_row);

			lang_switch = new Gtk.Switch () {
				valign = Gtk.Align.CENTER
			};

			lang_dropdown = new Gtk.DropDown (app.app_locales.list_store, null) {
				expression = new Gtk.PropertyExpression (typeof (Tuba.Locales.Locale), null, "name"),
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
										new Tuba.Locales.Locale (locale_str, null, null),
										Tuba.Locales.Locale.compare,
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
										before_calendar.year = year;
										before_calendar.month = month;
										before_calendar.day = day;
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
										during_calendar.year = year;
										during_calendar.month = month;
										during_calendar.day = day;
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
										after_calendar.year = year;
										after_calendar.month = month;
										after_calendar.day = day;
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
				props += @"language:$(((Tuba.Locales.Locale) lang_dropdown.selected_item).locale)";
			}

			result (@"$final_query $(string.joinv (" ", props))");
			on_exit ();
		}

		[GtkCallback] void on_exit () {
			this.force_close ();
		}
	}
}
