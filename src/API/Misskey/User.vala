public class Tuba.API.Misskey.User : Entity, Widgetizable, AiChanify, Json.Serializable {
    public string id { get; set; }
    public string name { get; set; }
    public string username { get; set; }
    public string host { get; set; }
    public string avatarUrl { get; set; }
    public string description { get; set; }
    public bool isLocked { get; set; }
    public string url { get; set; }
    public string createdAt { get; set; }
    public string bannerUrl { get; set; }
    public int64 followersCount { get; set; }
    public int64 followingCount { get; set; }
    public int64 notesCount { get; set; }

    public static User from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Misskey.User), node) as API.Misskey.User;
	}

    public override Entity to_mastodon () {
        var masto_acc = new API.Account.empty (id);
        masto_acc.username = username;
        masto_acc.acct = host != null ? @"$username@$host" : username;
        masto_acc.note = description ?? "";
        masto_acc.locked = isLocked;
        masto_acc.header = bannerUrl;
        masto_acc.avatar = avatarUrl;
        masto_acc.url = url ?? @"$host/@$username";
        masto_acc.followers_count = followersCount;
        masto_acc.following_count = followingCount;
        masto_acc.statuses_count = notesCount;
        masto_acc.created_at = createdAt;

        return masto_acc;
    }

    public override Gtk.Widget to_widget () {
		return to_mastodon ().to_widget ();
	}
}
