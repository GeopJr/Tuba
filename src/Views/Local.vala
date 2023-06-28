public class Tuba.Views.Local : Views.Timeline {
	public Local () {
		Object (
			url: "/api/notes/local-timeline",
			is_public: true,
			label: _("Local"),
			icon: "tuba-network-server-symbolic"
		);
        accepts = typeof (API.Misskey.Note);
	}

    //  public override Request append_params (Request r) {
    //      var req = base.append_params (r);
    //      req.with_param ("local", "true");
    //      return req;
    //  }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=public:local&access_token=$(account.access_token)" : null;
    }

}
