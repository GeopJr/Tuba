public class Tuba.Views.Bubble : Views.Timeline {
	construct {
		url = accounts.active.tuba_api_versions.chuckya > 0
			? "/api/v1/timelines/public?bubble=true&only_media=false"
			: "/api/v1/timelines/bubble";
		label = "Bubble"; // NOTE: Leave untranslated for now
		icon = "tuba-fish-symbolic";
		is_public = true;
	}

	public override string? get_stream_url () {
		return account != null && account.tuba_api_versions.chuckya > 0
			? @"$(account.instance)/api/v1/streaming?stream=public:bubble&access_token=$(account.access_token)"
			: null;
	}
}
