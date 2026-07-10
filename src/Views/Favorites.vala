public class Tuba.Views.Favorites : Views.Timeline {
	public Favorites () {
		Object (
			url: "/api/v1/favourites",
			label: _("Favorites"),
			empty_state_title: _("No Favorites")
		);
	}
}
