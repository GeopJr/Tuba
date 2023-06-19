public class Tuba.Views.Federated : Views.Timeline {

	public Federated () {
		Object (
			url: "/api/notes/global-timeline",
			is_public: true,
			label: _("Federated"),
			icon: "tuba-globe-symbolic"
		);
	}

	public override string? get_stream_url () {
		return account != null ? @"$(account.instance)/api/v1/streaming/?stream=public&access_token=$(account.access_token)" : null;
	}

}
