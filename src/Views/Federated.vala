public class Tootle.Views.Federated : Views.Timeline {

    public Federated () {
        Object (timeline: "public", is_public: true);
    }

    public override string get_icon () {
        return "network-workgroup-symbolic";
    }

    public override string get_name () {
        return _("Federated Timeline");
    }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=public&access_token=$(account.token)" : null;
    }

}
