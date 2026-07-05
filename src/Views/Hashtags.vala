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

	construct {
		url = "/api/v1/followed_tags";
		label = _("Hashtags");
		icon = "tuba-hashtag-symbolic";
		accepts = typeof (FavoriteTag);
		empty_state_title = _("No Hashtags");
		batch_size_min = 20;
	}

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
		Widgets.StatusActionButton tuba_fav_button;

		public Dialogs.HashtagList.Data? tuba_hashtag_data { get; set; default = null; }

		public override Gtk.Widget to_widget () {
			var row = (Adw.ActionRow) base.to_widget ();

			if (this.tuba_hashtag_data == null) {
				tuba_fav_button = new Widgets.StatusActionButton.with_icon_name ("tuba-unstarred-symbolic") {
					active_icon_name = "tuba-starred-symbolic",
					css_classes = { "ttl-status-action-star", "flat", "circular" },
					valign = Gtk.Align.CENTER,
					halign = Gtk.Align.CENTER,
					tooltip_text = _("Favorite"),
				};
				tuba_fav_button.clicked.connect (on_favorite_button_clicked);
				row.add_prefix (tuba_fav_button);
				settings.notify["favorite-tags-ids"].connect (on_fav_tags_updated);
				update_fav_status ();
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

		private void update_fav_status () {
			bool in_list = false;

			string down_name = this.name.down ();
			foreach (var tag_name in settings.favorite_tags_ids) {
				if (tag_name.down () == down_name) {
					in_list = true;
					break;
				}
			}

			tuba_fav_button.active = in_list;
			on_fav_tags_updated ();
		}

		private void on_favorite_button_clicked () {
			tuba_fav_button.active = !tuba_fav_button.active;

			if (tuba_fav_button.active) {
				add_to_favs ();
			} else {
				remove_from_favs ();
			}
		}

		private void on_fav_tags_updated () {
			tuba_fav_button.sensitive = tuba_fav_button.active || settings.favorite_tags_ids.length < Views.Sidebar.MAX_SIDEBAR_TAGS;
		}

		private void add_to_favs () {
			string[] res = {};

			string down_name = this.name.down ();
			foreach (var tag_name in settings.favorite_tags_ids) {
				if (tag_name.down () != down_name) res += tag_name;
			}
			res += this.name;

			settings.favorite_tags_ids = res;
			GLib.Idle.add (accounts.active.gather_fav_tags);
		}

		private void remove_from_favs () {
			string[] new_ids = {};

			string down_name = this.name.down ();
			foreach (string tag_name in settings.favorite_tags_ids) {
				if (down_name != tag_name.down ()) new_ids += tag_name;
			}

			settings.favorite_tags_ids = new_ids;
			GLib.Idle.add (accounts.active.gather_fav_tags);
		}
	}
}
