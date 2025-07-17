public class Tuba.Views.Hashtags : Views.Timeline {
	construct {
		url = "/api/v1/followed_tags";
		label = _("Hashtags");
		icon = "tuba-hashtag-symbolic";
		accepts = typeof (FavoriteTag);
		empty_state_title = _("No Hashtags");
	}

	public class FavoriteTag : API.Tag, Widgetizable {
		Widgets.StatusActionButton tuba_fav_button;

		public override Gtk.Widget to_widget () {
			var row = (Adw.ActionRow) base.to_widget ();

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

			return row;
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
