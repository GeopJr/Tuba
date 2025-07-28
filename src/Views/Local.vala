public class Tuba.Views.Local : Views.Federated {
	construct {
		label = _("Local");
		icon = "tuba-people-symbolic";
	}

	public override Request append_params (Request r) {
		var req = base.append_params (r);
		req.with_param ("local", "true");
		return req;
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.tuba_streaming_url)/api/v1/streaming?stream=public:local&access_token=$(account.access_token)"
			: null;
	}
}
