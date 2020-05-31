public class Tootle.Views.Local : Views.Federated {

    public Local () {
        label = _("Local");
        icon = Desktop.fallback_icon ("system-users-symbolic", "document-open-recent-symbolic");
    }

    public override Request append_params (Request req) {
        req.with_param ("local", "true");
        req.with_param ("limit", limit.to_string ());
        return req;
    }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=public:local&access_token=$(account.token)" : null;
    }

}
