public class Tuba.Views.Federated : Views.Timeline {
	public Federated () {
		Object (
			url: "/api/v1/timelines/public",
			label: _("Federated"),
			icon: "tuba-globe-symbolic"
		);
	}

	construct {
		is_public = true;
	}

	public override string? get_stream_url () {
		return account != null
			? @"$(account.tuba_streaming_url)/api/v1/streaming?stream=public&access_token=$(account.access_token)"
			: null;
	}
}
