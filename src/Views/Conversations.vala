public class Tootle.Views.Conversations : Views.Timeline {

    public Conversations () {
        Object (
            url: "/api/v1/conversations",
            label: _("Conversations"),
            icon: API.Visibility.DIRECT.get_icon (),
            accepts: typeof (API.Conversation)
        );
    }

    public override string? get_stream_url () {
        return @"/api/v1/streaming/?stream=direct&access_token=$(accounts.active.token)";
    }

}
