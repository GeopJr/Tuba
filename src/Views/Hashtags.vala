public class Tuba.Views.Hashtags : Views.Timeline {
    construct {
        url = "/api/v1/followed_tags";
        label = _("Hashtags");
        icon = "tuba-hashtag-symbolic";
        accepts = typeof (API.Tag);
    }
}
