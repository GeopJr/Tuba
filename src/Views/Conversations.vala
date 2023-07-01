public class Tuba.Views.Conversations : Views.Timeline {
    public Conversations () {
        Object (
            url: "/api/v1/conversations",
            label: _("Conversations"),
            icon: "tuba-mail-symbolic"
        );
        accepts = typeof (API.Conversation);
        stream_event[InstanceAccount.EVENT_CONVERSATION].connect (on_new_post);
    }

    public override string? get_stream_url () {
		return account != null
            ? @"$(account.instance)/api/v1/streaming/?stream=direct&access_token=$(account.access_token)"
            : null;
    }
}
