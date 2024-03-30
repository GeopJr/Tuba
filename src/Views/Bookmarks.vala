public class Tuba.Views.Bookmarks : Views.Timeline {
	construct {
		url = "/api/v1/bookmarks";
		label = _("Bookmarks");
		icon = "tuba-bookmarks-symbolic";
		empty_state_title = _("No Bookmarks");
	}
}
