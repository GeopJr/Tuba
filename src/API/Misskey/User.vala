public class Tuba.API.Misskey.User : Entity {
	~Note () {
		message ("[OBJ] Destroyed "+uri);
	}

    public string id { get; set; }
    public string createdAt { get; set; default = "0"; }
    public string text { get; set; default = ""; }
    public string? cw { get; set; default = null; }
    public API.Account user { get; set; }
    public string? replyId { get; set; default = null; }
    public string visibility { get; set; default = settings.default_post_visibility; }
    public Gee.ArrayList<API.Mention>? mentions { get; set; default = null; }
    public API.Poll? poll { get; set; default = null; }
    public Gee.ArrayList<API.Emoji>? emojis { get; set; }
    public Gee.ArrayList<API.EmojiReaction>? reactions { get; set; default = null; }
    public int64 renotesCount { get; set; default = 0; }
    public int64 repliesCount { get; set; default = 0; }
    public string uri { get; set; }
    public string url { get; set; }
    public API.Misskey.Note? renote { get; set; default = null; }
}
