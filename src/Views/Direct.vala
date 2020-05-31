public class Tootle.Views.Direct : Views.Timeline {

    public Direct () {
        Object (
            timeline: "direct",
            label: _("Direct Messages"),
            icon: "mail-send-symbolic"
        );
    }

    public override string? get_stream_url () {
        return @"/api/v1/streaming/?stream=direct&access_token=$(accounts.active.token)";
    }

}
