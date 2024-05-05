public class Tuba.Views.StatusStats : Views.TabbedBase {
	Views.ContentBase favorited;
	Views.ContentBase boosted;

	construct {
		label = _("Post Stats");
	}

    public StatusStats (string status_id) {
		favorited = add_timeline_tab (
			// translators: title for a list of people that favorited a post
			_("Favorited By"),
			"tuba-starred-symbolic",
			@"/api/v1/statuses/$(status_id)/favourited_by",
			typeof (API.Account),
			_("No Favorites")
		);

		boosted = add_timeline_tab (
			// translators: title for a list of people that boosted a post
			_("Boosted By"),
			"tuba-media-playlist-repeat-symbolic",
			@"/api/v1/statuses/$(status_id)/reblogged_by",
			typeof (API.Account),
			_("No Boosts")
		);
    }
}
