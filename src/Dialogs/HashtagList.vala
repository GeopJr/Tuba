public class Tuba.Dialogs.HashtagList : Adw.PreferencesDialog {
	//  public signal void created (Data data);
	public signal void created ();

	public class Data : GLib.Object {
		public string title { get; private set; }
		public string uuid { get; private set; }

		string[] any;
		string[] all;
		string[] none;

		public string[] get_any () {
			return this.any;
		}

		public string[] get_all () {
			return this.all;
		}

		public string[] get_none () {
			return this.none;
		}

		public Data (string title, string[] any, string[] all, string[] none, string? uuid = null) {
			this.title = title;
			this.any = any;
			this.all = all;
			this.none = none;
			this.uuid = uuid == null ? GLib.Uuid.string_random () : uuid;
		}

		// uuid:title:tag;any:tag;none...
		public Data.from_string (string data_string)	{
			var parts = data_string.split (":");
			this.title = "";
			this.any = {};
			this.all = {};
			this.none = {};

			for (int i = 0; i < parts.length; i++) {
				switch (i) {
					case 0:
						this.uuid = parts[i];
						break;
					case 1:
						this.title = GLib.Uri.unescape_string (parts[i]);
						break;
					default:
						var sub_parts = parts[i].split (";");
						if (sub_parts.length == 2) {
							string tag = GLib.Uri.unescape_string (sub_parts[0]);
							switch (sub_parts[1]) {
								case "any":
									this.any += tag;
									break;
								case "all":
									this.all += tag;
									break;
								case "none":
									this.none += tag;
									break;
							}
						}
						break;
				}
			}

			if (this.uuid == null) this.uuid = GLib.Uuid.string_random ();
		}

		public string to_string () {
			string[] final_strings = {this.uuid, GLib.Uri.escape_string (this.title)};
			foreach (var tag in this.any) {
				final_strings += @"$(GLib.Uri.escape_string (tag));any";
			}
			foreach (var tag in this.all) {
				final_strings += @"$(GLib.Uri.escape_string (tag));all";
			}
			foreach (var tag in this.none) {
				final_strings += @"$(GLib.Uri.escape_string (tag));none";
			}
			return string.joinv (":", final_strings);
		}

		public string to_uri_part () {
			string main = "";
			int start_any = 0;
			int start_all = 0;

			#if false
				// the way the tag timeline works is
				// /main_tag?all[]=...&any=[]=...&none[]=...
				// to make it feel like creating a list to users
				// we skip the whole "pick a main tag" and get it
				// from the all or any lists (since they cant be empty).
				// The problem is that the behavior behind the filters
				// is main_tag including all_tags plus any of the
				// any_tags minus all of the none_tags
				// so say for example all(gnome, elementary)
				// any(libadwaita, granite). If we take the
				// main_tag from any_tags, it will become
				// libadwaita + gnome + elementary + granite
				// but the user wanted
				// gnome + elementary + (libadwaita || granite)
				// So it's important to take the main_tag
				// from all_tags, unless it's empty
				if (all.length > 0) {
					main = GLib.Uri.escape_string (all[0]);
					start_all += 1;
				} else {
					main = GLib.Uri.escape_string (any[0]);
					start_any += 1;
				}
			#else
				// orrrrrr not.
				// ignore the above as it turns out Mastodon
				// completely ignores the main tag????
				// so let's leave it at its original position.
				// I'll keep the above, in case they fix it
				if (all.length > 0) {
					main = GLib.Uri.escape_string (all[0]);
				} else {
					main = GLib.Uri.escape_string (any[0]);
				}
			#endif

			string[] final_params = {};
			string brackets_encoded = GLib.Uri.escape_string ("[]");
			for (int i = start_any; i < any.length; i++) {
				final_params += @"any$brackets_encoded=$(GLib.Uri.escape_string (any[i]))";
			}
			for (int i = start_all; i < all.length; i++) {
				final_params += @"all$brackets_encoded=$(GLib.Uri.escape_string (all[i]))";
			}
			foreach (var tag in this.none) {
				final_params += @"none$brackets_encoded=$(GLib.Uri.escape_string (tag))";
			}

			return @"$main?$(string.joinv ("&", final_params))";
		}

		public string to_sub () {
			string[] sub = {};
			if (this.any.length > 0) {
				sub += @"$(_("Any")): $(string.joinv (", ", this.any))";
			}
			if (this.all.length > 0) {
				sub += @"$(_("All")): $(string.joinv (", ", this.all))";
			}
			if (this.none.length > 0) {
				sub += @"$(_("None")): $(string.joinv (", ", this.none))";
			}
			return string.joinv (" | ", sub);
		}
	}

	public class HashtagSearch : Gtk.Popover {
		public signal void tag_picked (string tag);
		public signal void errored (string error_msg);
		Gtk.SearchEntry entry;
		Gtk.ListBox result_box;

		construct {
			this.add_css_class ("emoji-picker");
			result_box = new Gtk.ListBox () {
				margin_end = 6,
				margin_bottom = 6,
				margin_start = 6
			};

			var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
			content_box.append (result_box);
			this.child = content_box;

			entry = new Gtk.SearchEntry () {
				//  text = query,
				hexpand = true,
				placeholder_text = "#GNOME",
				search_delay = 300
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

		protected void on_close () {
			this.popdown ();
		}

		private void search () {
			search_real.begin (entry.text.strip ());
		}

		RequestV2? last_req = null;
		private async void search_real (string query) {
			result_box.remove_all ();

			if (last_req != null) {
				last_req.cancellable.cancel ();
				last_req = null;
			}
			if (query == "") return;
			try {
				last_req = API.Tag.search (query);
				var in_stream = yield last_req.exec (null);
				if (last_req == null || last_req.cancellable.is_cancelled ()) return;

				Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
				var results = API.SearchResults.from (network.parse_node (parser));
				if (results != null) {
					int i = 0;
					results.hashtags.foreach (tag => {
						var widget = new Widgets.Tag ((API.Tag) tag) {
							css_classes = {"border-radius-6"}
						};
						widget.activated.connect (on_tag_chosen);
						result_box.append (widget);
						i += 1;
						return i < 4;
					});
				}
			} catch (GLib.IOError.CANCELLED e) {
				debug ("Message is cancelled.");
			} catch (Error e) {
				errored (e.message);
				warning (@"Couldn't search tag $query: $(e.code) $(e.message)");
			}

			last_req = null;
		}

		protected void on_tag_chosen (Adw.ActionRow tag) {
			on_close ();

			Widgets.Tag tag_row = (Widgets.Tag) tag;
			tag_picked (tag_row.name.has_prefix ("#") ? tag_row.name : @"#$(tag_row.name)");
		}

		public override void show () {
			base.show ();
			entry.grab_focus ();
		}
	}

	private class HashtagGroup : Adw.PreferencesGroup {
		const int MAX_TAGS = 4;

		Gtk.MenuButton menu_button;
		Gee.ArrayList<string> _tags = new Gee.ArrayList<string> ();

		public signal void errored (string error_msg);
		public string[] tags { owned get {return _tags.to_array ();}}
		public bool empty { get { return _tags.size == 0; } }

		public HashtagGroup (string title, string description) {
			this.title = title;
			this.description = description;

			var popover = new HashtagSearch ();
			menu_button = new Gtk.MenuButton () {
				icon_name = "tuba-plus-large-symbolic",
				popover = popover,
				valign = Gtk.Align.CENTER,
				css_classes = {"flat"}
			};
			popover.tag_picked.connect (add_row);
			popover.errored.connect (on_error);
			this.header_suffix = menu_button;
		}

		private void on_error (string error) {
			errored (error);
		}

		private class TagRow : Adw.ActionRow {
			public signal void deleted ();
			public string tag { get; private set; }

			public TagRow (string tag) {
				this.tag =
				this.title = tag.has_prefix ("#") ? tag.slice (1, tag.length) : tag;
				this.activatable = false;
				this.add_prefix (new Gtk.Image.from_icon_name ("tuba-hashtag-symbolic"));

				var delete_btn = new Gtk.Button.from_icon_name ("user-trash-symbolic") {
					css_classes = { "circular", "flat", "error" },
					tooltip_text = _("Remove"),
					valign = Gtk.Align.CENTER
				};
				delete_btn.clicked.connect (on_delete);
				this.add_suffix (delete_btn);
			}

			private void on_delete () {
				deleted ();
			}
		}

		private void add_row (string tag) {
			var row = new TagRow (tag);
			if (_tags.contains (row.tag)) return;

			row.deleted.connect (on_delete);
			this.add (row);
			_tags.add (row.tag);
			menu_button.sensitive = _tags.size < MAX_TAGS;
		}

		private void on_delete (TagRow row) {
			this.remove (row);
			_tags.remove (row.tag);
			menu_button.sensitive = _tags.size < MAX_TAGS;
		}

		public void fill_from_array (string[] tags) {
			for (int i = 0; i < int.min (tags.length, MAX_TAGS); i++) {
				add_row (tags[i]);
			}
		}
	}

	Adw.EntryRow name_row;
	HashtagGroup all;
	HashtagGroup any;
	HashtagGroup none;
	string? editing_uuid = null;
	public HashtagList (Data? data = null) {
		// translators: dialog title that creates a list of hashtags
		this.title = data == null ? _("Hashtag List") : data.title;
		this.content_width = 500;
		this.content_height = 450;
		this.can_close = false;
		this.close_attempt.connect (on_close_attempt);
		if (data != null) this.editing_uuid = data.uuid;

		var general_page = new Adw.PreferencesPage () {
			title = _("Hashtag List"),
			icon_name = "tuba-hashtag-symbolic"
		};
		var name_group = new Adw.PreferencesGroup ();
		name_row = new Adw.EntryRow () {
			title = _("Title")
		};
		if (data != null) name_row.text = data.title;
		name_group.add (name_row);
		general_page.add (name_group);

		any = new HashtagGroup (
			// translators: title on hashtags list group, "Any hashtags"
			_("Any"),
			// translators: description on hashtags list group, above a list of hashtags
			_("Include posts that contain any of these tags.")
		);
		if (data != null) any.fill_from_array (data.get_any ());
		any.errored.connect (on_error);
		general_page.add (any);

		all = new HashtagGroup (
			_("All"),
			// translators: description on hashtags list group, above a list of hashtags
			_("Include posts that contain all of these tags.")
		);
		if (data != null) all.fill_from_array (data.get_all ());
		all.errored.connect (on_error);
		general_page.add (all);

		none = new HashtagGroup (
			_("None"),
			// translators: description on hashtags list group, above a list of hashtags
			_("Don't include posts that contain any of these tags.")
		);
		if (data != null) none.fill_from_array (data.get_none ());
		none.errored.connect (on_error);
		general_page.add (none);

		this.add (general_page);
	}

	private void on_error (string error) {
		this.add_toast (new Adw.Toast (error) {
			timeout = 5
		});
	}

	private void on_close_attempt () {
		string title = name_row.text.strip ();
		if (title == "" && any.empty && all.empty) {
			this.force_close ();
			return;
		}

		var dlg = new Adw.AlertDialog (
			// translators: Dialog title when closing the Hashtag List creation dialog
			this.editing_uuid == null ? _("Create Hashtag List?") : _("Save Hashtag List?"),
			null
		);

		dlg.add_response ("cancel", _("Cancel"));
		dlg.set_response_appearance ("cancel", Adw.ResponseAppearance.DEFAULT);

		dlg.add_response ("discard", _("Discard"));
		dlg.set_response_appearance ("discard", Adw.ResponseAppearance.DESTRUCTIVE);

		dlg.add_response ("create", this.editing_uuid == null ? _("Create") : _("Save"));
		dlg.set_response_appearance ("create", Adw.ResponseAppearance.SUGGESTED);

		dlg.default_response = "cancel";

		dlg.choose.begin (this, null, (obj, res) => {
			switch (dlg.choose.end (res)) {
				case "discard":
					this.force_close ();
					break;
				case "create":
					create_list_and_close (title);
					break;
			}
		});
	}

	private void create_list_and_close (string title) {
		if (title == "") {
			this.add_toast (new Adw.Toast (_("Name cannot be empty")) {
				timeout = 5
			});
			return;
		} else if (any.empty && all.empty) {
			// translators: error shown when trying to create a hashtag list while the "Any" and "All" lists
			//				are empty at the same time (one of them needs to have at least 1 item)
			this.add_toast (new Adw.Toast (_("\"Any\" or \"All\" cannot be empty")) {
				timeout = 5
			});
			return;
		}

		//  created (new Data (title, any.tags, all.tags, none.tags));
		save_hashtag_list (new Data (title, any.tags, all.tags, none.tags, this.editing_uuid));
		created ();
		this.force_close ();
	}

	private void save_hashtag_list (Data data) {
		string[] new_tag_lists = {};
		string uuid_prefix = @"$(data.uuid):";
		bool updated = false;

		foreach (string tag_list in settings.hashtag_lists) {
			if (tag_list.has_prefix (uuid_prefix)) {
				updated = true;
				new_tag_lists += data.to_string ();
			} else {
				new_tag_lists += tag_list;
			}
		}

		if (!updated) {
			new_tag_lists += data.to_string ();
		}

		settings.hashtag_lists = new_tag_lists;
	}

	public static void remove_hashtag_list (string uuid) {
		string[] new_tag_lists = {};
		string uuid_prefix = @"$uuid:";
		foreach (string tag_list in settings.hashtag_lists) {
			if (!tag_list.has_prefix (uuid_prefix)) new_tag_lists += tag_list;
		}
		settings.hashtag_lists = new_tag_lists;
	}
}
