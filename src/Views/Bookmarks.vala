public class Tooth.Views.Bookmarks : Views.Timeline {

    public Bookmarks () {
        Object (
            url: "/api/v1/bookmarks",
            label: _("Bookmarks"),
            icon: "tooth-bookmarks-symbolic"
        );
    }

}
