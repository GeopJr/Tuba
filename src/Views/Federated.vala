public class Tuba.Views.Federated : Views.Timeline {
	construct {
		url = "/api/v1/timelines/public";
		label = _("Federated");
		icon = "tuba-globe-symbolic";
		is_public = true;
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.tuba_streaming_url)/api/v1/streaming?stream=public&access_token=$(account.access_token)"
			: null;
	}
}
