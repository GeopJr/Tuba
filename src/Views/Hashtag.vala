public class Tootle.Views.Hashtag : Views.Timeline {

    public Hashtag (string hashtag) {
        base ("tag/" + hashtag);
    }
    
    public string get_hashtag () {
        return this.timeline.substring (4);
    }
    
    public override string get_name () {
        return get_hashtag ();
    }
    
    public override Soup.Message? get_stream () {
        var url = "%s/api/v1/streaming/?stream=hashtag&tag=%s&access_token=%s".printf (accounts.formal.instance, get_hashtag (), accounts.formal.token);
        return new Soup.Message("GET", url);
    }

}
