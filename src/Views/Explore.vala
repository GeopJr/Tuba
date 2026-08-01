public class Tuba.Views.Explore : Views.TabbedBase {
	construct {
		label = _("Explore");
		uid = 1;

		add_timeline_tab (
			_("Posts"), "tuba-chat-symbolic", "/api/v1/trends/statuses", typeof (API.Status));
		add_timeline_tab (
			_("Hashtags"), "tuba-hashtag-symbolic", "/api/v1/trends/tags", typeof (API.Tag),
			// translators: empty state title
			_("No Hashtags")
		);
		add_timeline_tab (
			// translators: explore tab category
			_("News"), "tuba-newspaper-symbolic", "/api/v1/trends/links", typeof (API.PreviewCard),
			// translators: empty state title
			_("No News")
		);
		add_timeline_tab (
			// translators: explore tab category
			_("For You"), "tuba-people-symbolic", "/api/v2/suggestions", typeof (API.Suggestion),
			// translators: empty state title
			_("No Suggestions")
		);
	}
}
