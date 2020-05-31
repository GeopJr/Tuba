public class Tootle.Views.Federated : Views.Timeline {

    public Federated () {
        Object (
        	timeline: "public",
        	is_public: true,
        	label: _("Federated"),
        	icon: "network-workgroup-symbolic"
        );
    }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=public&access_token=$(account.token)" : null;
    }

}
