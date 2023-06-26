public class Tuba.Views.Bookmarks : Views.Timeline {

    public Bookmarks () {
        Object (
            url: "/api/i/favorites",
            label: _("Bookmarks"),
            icon: "tuba-bookmarks-symbolic"
        );
    }

}
