public class Tuba.Views.StatusStats : Views.TabbedBase {
	Views.ContentBase favorited;
	Views.ContentBase boosted;
	Views.ContentBase reacted;

	construct {
		label = _("Post Stats");
	}

	public StatusStats (string status_id, bool has_reactors = false) {
		favorited = add_timeline_tab (
			// translators: title for a list of people that favorited a post
			_("Favorited By"),
			"tuba-starred-symbolic",
			@"/api/v1/statuses/$(status_id)/favourited_by",
			typeof (API.Account),
			_("No Favorites"),
			"tuba-heart-broken-symbolic"
		);

		boosted = add_timeline_tab (
			// translators: title for a list of people that boosted a post
			_("Boosted By"),
			"tuba-media-playlist-repeat-symbolic",
			@"/api/v1/statuses/$(status_id)/reblogged_by",
			typeof (API.Account),
			_("No Boosts"),
			"tuba-heart-broken-symbolic"
		);

		if (has_reactors && accounts.active.instance_info != null && accounts.active.instance_info.pleroma != null) {
			reacted = add_timeline_tab (
				// translators: title for a list of people that have reacted to a post
				_("Reactions"),
				"tuba-smile-symbolic",
				@"/api/v1/pleroma/statuses/$(status_id)/reactions",
				typeof (API.EmojiReaction),
				_("No Reactions"),
				"tuba-heart-broken-symbolic"
			);
		}
	}
}
