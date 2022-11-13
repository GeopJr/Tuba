public class Tooth.Views.Hashtag : Views.Timeline {

    public Hashtag (string tag) {
        Object (
        	url: @"/api/v1/timelines/tag/$tag",
        	label: "#"+tag
        );
    }

    public override string? get_stream_url () {
        var tag = url.substring (4);
        return account != null ? @"$(account.instance)/api/v1/streaming/?stream=hashtag&tag=$tag&access_token=$(account.access_token)" : null;
    }

}
