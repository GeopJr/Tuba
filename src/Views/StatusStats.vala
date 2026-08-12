public class Tuba.Views.StatusStats : Views.TabbedBase {
	Views.ContentBase favorited;
	Views.ContentBase boosted;
	Views.ContentBase reacted;
	Views.ContentBase quoted;

	construct {
		// translators: post statistics view title (favs, boosts, reactions, quotes)
		label = _("Post Stats");
	}

	public StatusStats (string status_id, bool has_reactors = false) {
		boosted = add_timeline_tab (
			// translators: title for a list of people that boosted a post, shown under "View Stats"
			_("Boosted By"),
			"tuba-media-playlist-repeat-symbolic",
			@"/api/v1/statuses/$(status_id)/reblogged_by",
			typeof (API.Account),
			// translators: empty state title
			_("No Boosts"),
			"tuba-heart-broken-symbolic",
			true
		);

		favorited = add_timeline_tab (
			// translators: title for a list of people that favorited a post, shown under "View Stats"
			_("Favorited By"),
			"tuba-starred-symbolic",
			@"/api/v1/statuses/$(status_id)/favourited_by",
			typeof (API.Account),
			// translators: empty state title
			_("No Favorites"),
			"tuba-heart-broken-symbolic",
			true
		);

		if (InstanceAccount.InstanceFeatures.QUOTE in accounts.active.tuba_instance_features) {
			quoted = add_timeline_tab (
				// translators: title for a list of quotes of a post, shown under "View Stats"
				_("Quotes"),
				"tuba-quotation-symbolic",
				@"/api/v1/statuses/$(status_id)/quotes",
				typeof (API.Status),
				_("No Quotes"),
				"tuba-heart-broken-symbolic",
				true
			);
		}

		if (has_reactors && accounts.active.instance_info != null && accounts.active.instance_info.pleroma != null) {
			reacted = add_timeline_tab (
				// translators: title for a list of people that have reacted to a post, shown under "View Stats".
				//				A reaction is not the same as a favorite or a boost,
				//				see https://github.com/glitch-soc/mastodon/pull/2462
				_("Reactions"),
				"tuba-smile-symbolic",
				@"/api/v1/pleroma/statuses/$(status_id)/reactions",
				typeof (API.EmojiReaction),
				// translators: Reactions page empty state.
				//				A reaction is not the same as a favorite or a boost,
				//				see https://github.com/glitch-soc/mastodon/pull/2462
				_("No Reactions"),
				"tuba-heart-broken-symbolic"
			);
		}
	}
}
