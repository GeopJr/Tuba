public class Tuba.Views.StatusStats : Views.TabbedBase {
	Views.ContentBase favorited;
	Views.ContentBase boosted;

    public StatusStats (string status_id) {
        Object ( label: _("Post Stats") );

		favorited = add_timeline_tab (_("Favorited By"), "tuba-person2-symbolic", @"/api/v1/statuses/$(status_id)/favourited_by", typeof (API.Account));
		boosted = add_timeline_tab (_("Boosted By"), "tuba-media-playlist-repeat-symbolic", @"/api/v1/statuses/$(status_id)/reblogged_by", typeof (API.Account));
    }
}
