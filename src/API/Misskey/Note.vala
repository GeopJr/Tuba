public class Tuba.API.Misskey.Note : Tuba.Misskey.Entity, AiChanify {
	~Note () {
		message ("[OBJ] Destroyed "+uri);
	}

    public string id { get; set; }
    public string createdAt { get; set; default = "0"; }
    public string text { get; set; default = ""; }
    public string? cw { get; set; default = null; }
    public API.Misskey.User user { get; set; }
    public string? replyId { get; set; default = null; }
    public string visibility { get; set; default = settings.default_post_visibility; }
    public Gee.ArrayList<string>? mentions { get; set; default = null; }
    //  public API.Poll? poll { get; set; default = null; }
    public Gee.ArrayList<API.Misskey.Emoji>? emojis { get; set; }
    public Gee.HashMap<string, string>? reactions { get; set; default = null; }
    public int64 renotesCount { get; set; default = 0; }
    public int64 repliesCount { get; set; default = 0; }
    public string uri { get; set; }
    public string url { get; set; }
    public API.Misskey.Note? renote { get; set; default = null; }

    public override Entity to_mastodon () {
        var masto_status = new API.Status.empty ();
        masto_status.id = id;
        masto_status.account = (API.Account) user.to_mastodon ();
        masto_status.spoiler_text = cw;
        masto_status.in_reply_to_id = replyId;
        masto_status.content = text;
        masto_status.replies_count = repliesCount;
        masto_status.reblogs_count = renotesCount;
        masto_status.visibility = visibility;
        masto_status.uri = uri;

        return masto_status;
    }
}
