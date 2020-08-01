public class Tootle.Views.Conversations : Views.Timeline {

    public Conversations () {
        Object (
            url: "/api/v1/conversations",
            label: _("Conversations"),
            icon: API.Visibility.DIRECT.get_icon ()
        );
        accepts = typeof (API.Conversation);
    }

	// TODO: Reload when an update is received
    // public override string? get_stream_url () {
    //     return @"/api/v1/streaming/?stream=direct&access_token=$(account.access_token)";
    // }

}
