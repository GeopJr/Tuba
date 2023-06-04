public class Tuba.Views.Federated : Views.Timeline {

	public Federated () {
		Object (
			url: "/api/v1/timelines/public",
			is_public: true,
			label: _("Federated"),
			icon: "tuba-globe-symbolic"
		);
	}

	public override bool filter (Entity entity) {
		return ((API.Status) entity).formal.favourites_count >= 10;
	}

	public override string? get_stream_url () {
		return account != null ? @"$(account.instance)/api/v1/streaming/?stream=public&access_token=$(account.access_token)" : null;
	}

}
