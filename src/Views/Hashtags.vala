public class Tuba.Views.Hashtags : Views.Timeline {
	public class HashtagList : Views.Timeline {
		public HashtagList (string title, string uri_part) {
			Object (
				uid: 3,
				url: @"/api/v1/timelines/tag/$uri_part",
				label: title,
				icon: "tuba-list-compact-symbolic"
			);
		}
	}

	public Hashtags () {
		Object (
			url: "/api/v1/followed_tags",
			label: _("Hashtags"),
			icon: "tuba-hashtag-symbolic",
			empty_state_title: _("No Hashtags"),
			batch_size_min: 200
		);
	}

	construct {
		accepts = typeof (FavoriteTag);
	}

	public override void on_request_finish () {
		if (!has_finished_request) model.sort (compare_func); // don't sort future pages
		base.on_request_finish ();
	}

	CompareDataFunc<FavoriteTag> compare_func = (a, b) => {
		return ((a.tuba_hashtag_data == null && b.tuba_hashtag_data == null)
			|| (a.tuba_hashtag_data != null && b.tuba_hashtag_data != null))
			? GLib.strcmp (a.name.down (), b.name.down ()) : 0;
	};

	protected override void build_header () {
		base.build_header ();

		var new_list = new Gtk.Button () {
			icon_name = "tuba-plus-large-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			css_classes = { "flat" },
			// translators: headerbar button tooltip, creates a list of hashtags
			tooltip_text = _("New Hashtag List")
		};
		new_list.clicked.connect (on_new_list);

		header.pack_end (new_list);
	}

	private void on_new_list () {
		var dlg = new Dialogs.HashtagList ();
		dlg.created.connect (on_created_list);
		dlg.present (app.main_window);
	}

	private void on_created_list () {
		on_refresh ();
	}

	public override void on_refresh () {
		base.on_refresh ();
		GLib.Idle.add (load_hashtag_lists);
	}

	public bool load_hashtag_lists () {
		Object[] to_add = {};
		foreach (string tag_list in settings.hashtag_lists) {
			var data = new Dialogs.HashtagList.Data.from_string (tag_list);
			to_add += new FavoriteTag () {
				name = data.title,
				tuba_hashtag_data = data
			};
		}
		if (to_add.length > 0) model.splice (0, 0, to_add);

		return GLib.Source.REMOVE;
	}

	public class FavoriteTag : API.Tag, Widgetizable {
		public class FavoriteButton : Widgets.StatusActionButton {
			private string tag { get; set; }
			private bool force_recheck { get; set; default = false; }
			public FavoriteButton (string tag, bool force_recheck = false) {
				Object (
					default_icon_name: "tuba-unstarred-symbolic"
				);
				this.tag = tag;
				this.force_recheck = force_recheck;

				this.active_icon_name = "tuba-starred-symbolic";
				this.css_classes = { "ttl-status-action-star", "flat", "circular" };
				this.valign = Gtk.Align.CENTER;
				this.halign = Gtk.Align.CENTER;
				this.tooltip_text = _("Favorite");

				this.clicked.connect (on_favorite_button_clicked);
				settings.notify["favorite-tags-ids"].connect (on_fav_tags_updated);
				update_fav_status ();

				if (force_recheck)
					app.fav_tags_changed.connect (update_fav_status);
			}

			private void on_favorite_button_clicked () {
				this.active = !this.active;

				if (this.active) {
					Views.Hashtags.add_tag_to_favs (this.tag);
				} else {
					Views.Hashtags.remove_tag_from_favs (this.tag);
				}

				if (!force_recheck) app.fav_tags_changed (this.tag);
			}

			private void on_fav_tags_updated () {
				this.sensitive = this.active || settings.favorite_tags_ids.length < Views.Sidebar.MAX_SIDEBAR_TAGS;
			}

			private void update_fav_status (string? changed_tag = null) {
				if (changed_tag != null && changed_tag.down () != this.tag.down ()) return;

				bool in_list = false;

				string down_name = this.tag.down ();
				foreach (var tag_name in settings.favorite_tags_ids) {
					if (tag_name.down () == down_name) {
						in_list = true;
						break;
					}
				}

				this.active = in_list;
				on_fav_tags_updated ();
			}
		}

		public Dialogs.HashtagList.Data? tuba_hashtag_data { get; set; default = null; }

		public override Gtk.Widget to_widget () {
			var row = (Adw.ActionRow) base.to_widget ();

			if (this.tuba_hashtag_data == null) {
				row.add_prefix (new FavoriteButton (this.name, true));
			} else {
				row.subtitle = this.tuba_hashtag_data.to_sub ();

				row.add_prefix (new Gtk.Image.from_icon_name ("tuba-list-compact-symbolic") {
					halign = CENTER,
					valign = Gtk.Align.CENTER,
					// match the star button width
					margin_start = 9,
					margin_end = 9
				});

				var edit_button = new Gtk.Button () {
					icon_name = "document-edit-symbolic",
					valign = Gtk.Align.CENTER,
					halign = Gtk.Align.CENTER,
					css_classes = { "flat", "circular" },
					tooltip_text = _("Edit")
				};
				edit_button.clicked.connect (on_edit_hashtag_list);
				row.add_suffix (edit_button);

				var delete_button = new Gtk.Button () {
					icon_name = "user-trash-symbolic",
					valign = Gtk.Align.CENTER,
					halign = Gtk.Align.CENTER,
					css_classes = { "flat", "circular", "error" },
					tooltip_text = _("Delete")
				};
				delete_button.clicked.connect (on_remove_hl_clicked);
				row.add_suffix (delete_button);
			}

			return row;
		}

		protected override void on_activated () {
			if (this.tuba_hashtag_data == null) {
				base.on_activated ();
			} else {
				app.main_window.open_view (new HashtagList (this.tuba_hashtag_data.title, this.tuba_hashtag_data.to_uri_part ()));
			}
		}

		private void on_edit_hashtag_list () {
			var dlg = new Dialogs.HashtagList (this.tuba_hashtag_data);
			dlg.created.connect (on_edited_list);
			dlg.present (app.main_window);
		}

		private void on_edited_list () {
			app.refresh ();
		}

		private void on_remove_hl_clicked () {
			Dialogs.HashtagList.remove_hashtag_list (this.tuba_hashtag_data.uuid);
			app.refresh ();
		}
	}

	public static void add_tag_to_favs (string name) {
		if (name in settings.favorite_tags_ids) return;

		string[] res = {};

		string down_name = name.down ();
		foreach (var tag_name in settings.favorite_tags_ids) {
			if (tag_name.down () != down_name) res += tag_name;
		}
		res += name;

		settings.favorite_tags_ids = res;
		GLib.Idle.add (accounts.active.gather_fav_tags);
	}

	public static void remove_tag_from_favs (string name) {
		if (
			settings.favorite_tags_ids.length == 0
			|| !(name in settings.favorite_tags_ids)
		) return;

		string[] new_ids = {};

		string down_name = name.down ();
		foreach (string tag_name in settings.favorite_tags_ids) {
			if (down_name != tag_name.down ()) new_ids += tag_name;
		}

		settings.favorite_tags_ids = new_ids;
		GLib.Idle.add (accounts.active.gather_fav_tags);
	}
}
