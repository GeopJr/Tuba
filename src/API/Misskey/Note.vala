public class Tuba.API.Misskey.Note : Entity, Widgetizable, Json.Serializable, AiChanify {
	~Note () {
		message (@"[OBJ] Destroyed $uri");
	}

    public string id { get; set; }
    public string createdAt { get; set; default = ""; }
    public string text { get; set; default = ""; }
    public string? cw { get; set; default = null; }
    public API.Misskey.User user { get; set; }
    public string? replyId { get; set; default = null; }
    public string visibility { get; set; default = settings.default_post_visibility; }
    public Gee.ArrayList<string>? mentions { get; set; default = null; }
    public Gee.ArrayList<string>? fileIds { get; set; default = null; }
    //  public API.Poll? poll { get; set; default = null; }
    public Gee.ArrayList<API.Misskey.Emoji>? emojis { get; set; }
    public Gee.HashMap<string, string>? reactions { get; set; default = null; }
    public int64 renotesCount { get; set; default = 0; }
    public int64 repliesCount { get; set; default = 0; }
    public string uri { get; set; }
    public string url { get; set; }
    public API.Misskey.Note? renote { get; set; default = null; }

    public static Note from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Misskey.Note), node) as API.Misskey.Note;
	}

    public override bool deserialize_property (string prop, out Value val, ParamSpec spec, Json.Node node) {
		var success = default_deserialize_property (prop, out val, spec, node);

        var type = spec.value_type;
		if (val.type () == Type.INVALID) {
			val.init (type);
			spec.set_value_default (ref val);
			type = spec.value_type;
		}

		if (type.is_a (typeof (Gee.ArrayList))) {
			Type contains;

			switch (prop) {
				case "mentions":
					return Entity.des_list_string (out val, node);
				case "emojis":
					contains = typeof (API.Misskey.Emoji);
					break;
				case "reactions":
					return Entity.des_map_string_string (out val, node);
				default:
					contains = typeof (Entity);
					break;
			}
			return des_list (out val, node, contains);
		}

		return success;
	}

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
        masto_status.created_at = createdAt;

        if (renote != null) {
            var reblog_status = renote.to_mastodon () as API.Status;

            if (text == null && (fileIds == null || fileIds.size == 0)) {
                masto_status.reblog = reblog_status;
            } else {
                masto_status.quote = reblog_status;
            }
        }

        return masto_status;
    }

    public override Gtk.Widget to_widget () {
		return to_mastodon ().to_widget ();
	}
}
