public class Tootle.Views.Direct : Views.Timeline {

    public Direct () {
        Object (timeline: "direct");
    }

    public override string get_icon () {
        return "mail-send-symbolic";
    }

    public override string get_name () {
        return _("Direct Messages");
    }

    public override string? get_stream_url () {
        return @"/api/v1/streaming/?stream=direct&access_token=$(accounts.active.token)";
    }

}
