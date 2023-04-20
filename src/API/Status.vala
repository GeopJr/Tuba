using Gee;

public class Tuba.API.Status : Entity, Widgetizable {

	~Status () {
		message ("[OBJ] Destroyed "+uri);
	}

    public string id { get; set; }
    public API.Account account { get; set; }
    public string uri { get; set; }
    public string? spoiler_text { get; set; default = null; }
    public string? in_reply_to_id { get; set; default = null; }
    public string? in_reply_to_account_id { get; set; default = null; }
    public string content { get; set; default = ""; }
    public StatusApplication? application { get; set; default = null; }
    public int64 replies_count { get; set; default = 0; }
    public int64 reblogs_count { get; set; default = 0; }
    public int64 favourites_count { get; set; default = 0; }
    public string created_at { get; set; default = "0"; }
    public bool reblogged { get; set; default = false; }
    public bool favourited { get; set; default = false; }
    public bool bookmarked { get; set; default = false; }
    public bool sensitive { get; set; default = false; }
    public bool muted { get; set; default = false; }
    public bool pinned { get; set; default = false; }
    public string? edited_at { get; set; default = null; }
    public string? language { get; set; default = null; }
    public string visibility { get; set; default = settings.default_post_visibility; }
    public API.Status? reblog { get; set; default = null; }
    public ArrayList<API.Mention>? mentions { get; set; default = null; }
    public ArrayList<API.EmojiReaction>? reactions { get; set; default = null; }
    public ArrayList<API.EmojiReaction>? emoji_reactions { get; set; default = null; }
    public API.Pleroma? pleroma { get; set; default = null; }
    public ArrayList<API.Attachment>? media_attachments { get; set; default = null; }
    public API.Poll? poll { get; set; default = null; }
    public Gee.ArrayList<API.Emoji>? emojis { get; set; }

    public Gee.HashMap<string, string>? emojis_map {
		owned get {
			return gen_emojis_map();
		}
	}

    private Gee.HashMap<string, string>? gen_emojis_map () {
        var res = new Gee.HashMap<string, string>();
        if (emojis != null && emojis.size > 0) {
            emojis.@foreach (e => {
                res.set(e.shortcode, e.url);
                return true;
            });
        }

        return res;
    }

    public ArrayList<API.EmojiReaction>? compat_status_reactions {
        get {
			if (emoji_reactions != null) {
                return emoji_reactions;
            } else if (pleroma != null && pleroma.emoji_reactions != null) {
                return pleroma.emoji_reactions;
            }

            return reactions;
		}
    }

    public string? t_url { get; set; }
    public string? url {
        owned get { return this.get_modified_url (); }
        set { this.t_url = value; }
    }
    string? get_modified_url () {
        if (this.t_url == null) {
            if (this.uri == null) return null;
            return this.uri.replace ("/activity", "");
        }
        return this.t_url;
    }

    public bool is_edited {
        get { return edited_at != null; }
    }

    public Status formal {
        get { return reblog ?? this; }
    }

    public bool has_spoiler {
        get {
            return formal.sensitive ||
                !(formal.spoiler_text == null || formal.spoiler_text == "");
        }
    }

    public bool can_be_boosted {
    	get {
    		return this.formal.visibility != "direct" && (this.formal.visibility != "private" || this.formal.account.is_self ());
    	}
    }

	public static Status from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Status), node) as API.Status;
	}

    public Status.empty () {
        Object (
        	id: ""
        );
    }

	public Status.from_account (API.Account account) {
	    Object (
	        id: "",
	        account: account,
	        created_at: account.created_at,
            emojis: account.emojis
	    );

        if (account.note == "")
            content = "";
        else if ("\n" in account.note)
            content = account.note.split ("\n")[0];
        else
            content = account.note;
	}

    public override Gtk.Widget to_widget () {
        return new Widgets.Status (this);
    }

	public override void open () {
		var view = new Views.Thread (formal);
		app.main_window.open_view (view);
	}

    public bool is_owned (){
        return formal.account.id == accounts.active.id;
    }

	public bool has_media () {
		return media_attachments != null && !media_attachments.is_empty;
	}

    public virtual string get_reply_mentions () {
        var result = "";
        if (account.acct != accounts.active.acct)
            result = @"$(account.handle) ";

        if (mentions != null) {
            foreach (var mention in mentions) {
                var equals_current = mention.acct == accounts.active.acct;
                var already_mentioned = mention.acct in result;

                if (!equals_current && !already_mentioned)
                    result += @"$(mention.handle) ";
            }
        }

        return result;
    }

    public Request action (string action) {
        var req = new Request.POST (@"/api/v1/statuses/$(formal.id)/$action").with_account (accounts.active);
        req.priority = Soup.MessagePriority.HIGH;
        return req;
    }

    public Request annihilate () {
        return new Request.DELETE (@"/api/v1/statuses/$id")
        	.with_account (accounts.active);
    }
}
