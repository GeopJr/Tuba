public class Tuba.Views.Home : Views.Timeline {
    public Home () {
        Object (
            url: "/api/notes/timeline",
            label: _("Home"),
            icon: "tuba-home-symbolic"
        );
    }

    public override string? get_stream_url () {
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=user&access_token=$(account.access_token)" : null;
    }
}
