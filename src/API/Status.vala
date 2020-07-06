using Gee;

public class Tootle.API.Status : Entity, Widgetizable {

    public string id { get; set; }
    public API.Account account { get; set; }
    public string uri { get; set; }
    public string? spoiler_text { get; set; default = null; }
    public string? in_reply_to_id { get; set; default = null; }
    public string? in_reply_to_account_id { get; set; default = null; }
    public string content { get; set; default = ""; }
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
    public API.Visibility visibility { get; set; default = settings.default_post_visibility; }
    public API.Status? reblog { get; set; default = null; }
    public ArrayList<API.Mention>? mentions { get; set; default = null; }
    public ArrayList<API.Attachment>? media_attachments { get; set; default = null; }

    public string? _url { get; set; }
    public string url {
        owned get { return this.get_modified_url (); }
        set { this._url = value; }
    }
    string get_modified_url () {
        if (this._url == null) {
            return this.uri.replace ("/activity", "");
        }
        return this._url;
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

	public static Status from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Status), node) as API.Status;
	}

    public Status.empty () {
        Object (
        	id: "",
        	visibility: settings.default_post_visibility
        );
    }

	public Status.from_account (API.Account account) {
	    Object (
	        id: "",
	        account: account,
	        created_at: account.created_at
	    );

        if (account.note == "")
            content = "";
        else if ("\n" in account.note)
            content = Html.remove_tags (account.note.split ("\n")[0]);
        else
            content = Html.remove_tags (account.note);
	}

    public override Gtk.Widget to_widget () {
        return new Widgets.Status (this);
    }

    public bool is_owned (){
        return formal.account.id == accounts.active.id;
    }

    public string get_reply_mentions () {
        var result = "";
        if (account.acct != accounts.active.acct)
            result = "@%s ".printf (account.acct);

        if (mentions != null) {
            foreach (var mention in mentions) {
                var equals_current = mention.acct == accounts.active.acct;
                var already_mentioned = mention.acct in result;

                if (!equals_current && ! already_mentioned)
                    result += "@%s ".printf (mention.acct);
            }
        }

        return result;
    }

    public void action (string action, owned Network.ErrorCallback? err = network.on_error) {
        new Request.POST (@"/api/v1/statuses/$(formal.id)/$action")
        	.with_account (accounts.active)
        	.then ((sess, msg) => {
        	    var node = network.parse_node (msg);
        	    var upd = API.Status.from (node).formal;
        	    patch (upd);
            })
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

    public void poof (owned Soup.SessionCallback? cb = null, owned Network.ErrorCallback? err = network.on_error) {
        new Request.DELETE (@"/api/v1/statuses/$id")
        	.with_account (accounts.active)
        	.then ((sess, msg) => {
        	    streams.force_delete (id);
        	    cb (sess, msg);
        	})
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

}
