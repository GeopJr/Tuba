public class Tuba.Views.Home : Views.Timeline {
    public Home () {
        Object (
            url: "/api/v1/timelines/home",
            label: _("Home"),
            icon: "tuba-home-symbolic"
        );
    }

    public override bool filter (Entity entity) {
        var status = (API.Status) entity;
		return !settings.only_op_home || (status.reblog == null && (status.in_reply_to_id == null || status.in_reply_to_account_id == null));
	}

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.access_token)" : null;
    }
}
