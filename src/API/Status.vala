using Gee;

public class Tootle.API.Status : GLib.Object {


    public int64 id { get; construct set; }
    public API.Account account { get; construct set; }
    public string uri { get; set; }
    public string? url { get; set; default = null; }
    public string? spoiler_text { get; set; default = null; }
    public string? in_reply_to_id { get; set; default = null; }
    public string? in_reply_to_account_id { get; set; default = null; }
    public string content { get; set; default = ""; }
    public int64 replies_count { get; set; default = 0; }
    public int64 reblogs_count { get; set; default = 0; }
    public int64 favourites_count { get; set; default = 0; }
    public string created_at { get; set; default = "0"; }
    public bool reblogged { get; set; default = false; }
    public bool favorited { get; set; default = false; }
    public bool sensitive { get; set; default = false; }
    public bool muted { get; set; default = false; }
    public bool pinned { get; set; default = false; }
    public API.Visibility visibility { get; set; default = API.Visibility.PUBLIC; }
    public API.Status? reblog { get; set; default = null; }
    public ArrayList<API.Mention>? mentions { get; set; default = null; }
    public ArrayList<API.Attachment>? attachments { get; set; default = null; }

    public Status formal {
        get { return reblog ?? this; }
    }

	public bool has_spoiler {
        get {
            return formal.spoiler_text != null || formal.sensitive;
        }
	}

    public Status (Json.Object obj) {
        Object (
            id: int64.parse (obj.get_string_member ("id")),
            account: new Account (obj.get_object_member ("account")),
            uri: obj.get_string_member ("uri"),
            created_at: obj.get_string_member ("created_at"),
            content: Html.simplify ( obj.get_string_member ("content")),
            sensitive: obj.get_boolean_member ("sensitive"),
            visibility: Visibility.from_string (obj.get_string_member ("visibility")),

            in_reply_to_id: obj.get_string_member ("in_reply_to_id") ?? null,
            in_reply_to_account_id: obj.get_string_member ("in_reply_to_account_id") ?? null,

            replies_count: obj.get_int_member ("replies_count"),
            reblogs_count: obj.get_int_member ("reblogs_count"),
            favourites_count: obj.get_int_member ("favourites_count")
        );

        if (obj.has_member ("url"))
            url = obj.get_string_member ("url");
        else
            url = obj.get_string_member ("uri").replace ("/activity", "");

        var spoiler = obj.get_string_member ("spoiler_text");
        if (spoiler != "")
            spoiler_text = Html.simplify (spoiler);

        if (obj.has_member ("reblogged"))
            reblogged = obj.get_boolean_member ("reblogged");
        if (obj.has_member ("favourited"))
            favorited = obj.get_boolean_member ("favourited");
        if (obj.has_member ("muted"))
            muted = obj.get_boolean_member ("muted");
        if (obj.has_member ("pinned"))
            pinned = obj.get_boolean_member ("pinned");

        if (obj.has_member ("reblog") && obj.get_null_member("reblog") != true)
            reblog = new Status (obj.get_object_member ("reblog"));

        obj.get_array_member ("mentions").foreach_element ((array, i, node) => {
            var entity = node.get_object ();
            if (entity != null) {
                if (mentions == null)
                    mentions = new ArrayList<API.Mention> ();
                mentions.add (new API.Mention (entity));
            }
        });

        obj.get_array_member ("media_attachments").foreach_element ((array, i, node) => {
            var entity = node.get_object ();
            if (entity != null) {
                if (attachments == null)
                    attachments = new ArrayList<API.Attachment> ();
                attachments.add (new API.Attachment (entity));
            }
        });
    }

    public Status.empty () {
        Object (id: -1);
    }

	public Status.from_account (API.Account account) {
	    Object (
	        id: 0,
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

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("uri");
        builder.add_string_value (uri);
        builder.set_member_name ("url");
        builder.add_string_value (url);
        builder.set_member_name ("content");
        builder.add_string_value (content);
        builder.set_member_name ("created_at");
        builder.add_string_value (created_at);
        builder.set_member_name ("visibility");
        builder.add_string_value (visibility.to_string ());
        builder.set_member_name ("sensitive");
        builder.add_boolean_value (sensitive);
        builder.set_member_name ("sensitive");
        builder.add_boolean_value (sensitive);
        builder.set_member_name ("replies_count");
        builder.add_int_value (replies_count);
        builder.set_member_name ("favourites_count");
        builder.add_int_value (favourites_count);
        builder.set_member_name ("reblogs_count");
        builder.add_int_value (reblogs_count);
        builder.set_member_name ("account");
        builder.add_value (account.serialize ());

        if (spoiler_text != null) {
            builder.set_member_name ("spoiler_text");
            builder.add_string_value (spoiler_text);
        }
        if (reblog != null) {
            builder.set_member_name ("reblog");
            builder.add_value (reblog.serialize ());
        }
        if (attachments != null) {
            builder.set_member_name ("media_attachments");
            builder.begin_array ();
            foreach (API.Attachment attachment in attachments)
                builder.add_value (attachment.serialize ());
            builder.end_array ();
        }
        if (mentions != null) {
            builder.set_member_name ("mentions");
            builder.begin_array ();
            foreach (API.Mention mention in mentions)
                builder.add_value (mention.serialize ());
            builder.end_array ();
        }

        builder.end_object ();
        return builder.get_root ();
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
        	.then_parse_obj (obj => {
        	    var status = new API.Status (obj).formal;
        	    formal.reblogged = status.reblogged;
        	    formal.favorited = status.favorited;
        	    formal.muted = status.muted;
        	    formal.pinned = status.pinned;
            })
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

    public void poof (owned Soup.SessionCallback? cb = null, owned Network.ErrorCallback? err = network.on_error) {
        new Request.DELETE (@"/api/v1/statuses/$id")
        	.with_account (accounts.active)
        	.then ((sess, msg) => {
        	    streams.status_removed (id);
        	    cb (sess, msg);
        	})
            .on_error ((status, reason) => err (status, reason))
        	.exec ();
    }

}
