public class Tuba.Views.Favorites : Views.Timeline {

    public Favorites () {
        Object (
            url: "/api/users/reactions",
            label: _("Favorites"),
            with_user_id: true
        );
        accepts = typeof (API.Misskey.Favorite);
    }

}
