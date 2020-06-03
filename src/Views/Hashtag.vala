public class Tootle.Views.Hashtag : Views.Timeline {

    public Hashtag (string tag) {
        Object (
        	url: @"/api/v1/timelines/tag/$tag"
        );
    }

    public override string? get_stream_url () {
        var tag = url.substring (4);
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=hashtag&tag=$tag&access_token=$(account.token)" : null;
    }

}
