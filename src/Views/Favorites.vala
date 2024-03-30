public class Tuba.Views.Favorites : Views.Timeline {
	construct {
		url = "/api/v1/favourites";
		label = _("Favorites");
		empty_state_title = _("No Favorites");
	}
}
