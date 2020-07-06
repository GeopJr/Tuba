public class Tootle.Views.Bookmarks : Views.Timeline {

    public Bookmarks () {
        Object (
            url: "/api/v1/bookmarks",
            label: _("Bookmarks"),
            icon: "user-bookmarks-symbolic"
        );
    }

}
