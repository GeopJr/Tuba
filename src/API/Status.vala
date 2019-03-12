public class Tootle.API.Status {

    public signal void updated ();

    public API.Account account;
    public int64 id;
    public string uri;
    public string url;
    public string? spoiler_text;
    public string content;
    public int64 replies_count;
    public int64 reblogs_count;
    public int64 favourites_count;
    public string created_at;
    public bool reblogged = false;
    public bool favorited = false;
    public bool sensitive = false;
    public bool muted = false;
    public bool pinned = false;
    public API.StatusVisibility visibility;
    public API.Status? reblog;
    public API.Mention[]? mentions;
    public API.Attachment[]? attachments;

    public Status (int64 _id) {
        id = _id;
    }

    public Status get_formal () {
        return reblog != null ? reblog : this;
    }

    public static Status parse (Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var status = new Status (id);

        status.account = Account.parse (obj.get_object_member ("account"));
        status.uri = obj.get_string_member ("uri");
        status.created_at = obj.get_string_member ("created_at");
        status.replies_count = obj.get_int_member ("replies_count");
        status.reblogs_count = obj.get_int_member ("reblogs_count");
        status.favourites_count = obj.get_int_member ("favourites_count");
        status.content = Html.simplify ( obj.get_string_member ("content"));
        status.sensitive = obj.get_boolean_member ("sensitive");
        status.visibility = StatusVisibility.from_string (obj.get_string_member ("visibility"));

        if (obj.has_member ("url"))
            status.url = obj.get_string_member ("url");
        else
            status.url = obj.get_string_member ("uri").replace ("/activity", "");

        var spoiler = obj.get_string_member ("spoiler_text");
        if (spoiler != "")
            status.spoiler_text = Html.simplify (spoiler);

        if (obj.has_member ("reblogged"))
            status.reblogged = obj.get_boolean_member ("reblogged");
        if (obj.has_member ("favourited"))
            status.favorited = obj.get_boolean_member ("favourited");
        if (obj.has_member ("muted"))
            status.muted = obj.get_boolean_member ("muted");
        if (obj.has_member ("pinned"))
            status.pinned = obj.get_boolean_member ("pinned");

        if (obj.has_member ("reblog") && obj.get_null_member("reblog") != true)
            status.reblog = Status.parse (obj.get_object_member ("reblog"));

        API.Mention[]? _mentions = {};
        obj.get_array_member ("mentions").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _mentions += API.Mention.parse (object);
        });
        if (_mentions.length > 0)
            status.mentions = _mentions;

        API.Attachment[]? _attachments = {};
        obj.get_array_member ("media_attachments").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _attachments += API.Attachment.parse (object);
        });
        if (_attachments.length > 0)
            status.attachments = _attachments;

        return status;
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
        return get_formal ().account.id == accounts.current.id;
    }

    public bool has_spoiler () {
        return get_formal ().spoiler_text != null || get_formal ().sensitive;
    }

    public string get_reply_mentions () {
        var result = "";
        if (account.acct != accounts.current.acct)
            result = "@%s ".printf (account.acct);

        if (mentions != null) {
            foreach (var mention in mentions) {
                var equals_current = mention.acct == accounts.current.acct;
                var already_mentioned = mention.acct in result;

                if (!equals_current && ! already_mentioned)
                    result += "@%s ".printf (mention.acct);
            }
        }

        return result;
    }

    public void set_reblogged (bool rebl = true) {
        var action = rebl ? "reblog" : "unreblog";
        var msg = new Soup.Message ("POST", "%s/api/v1/statuses/%lld/%s".printf (accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            reblogged = rebl;
            updated ();
            if (rebl)
                app.toast (_("Boosted!"));
            else
                app.toast (_("Removed boost"));
        });
        network.queue (msg);
    }

    public void set_favorited (bool fav = true) {
        var action = fav ? "favourite" : "unfavourite";
        var msg = new Soup.Message ("POST", "%s/api/v1/statuses/%lld/%s".printf (accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            favorited = fav;
            updated ();
            if (fav)
                app.toast (_("Favorited!"));
            else
                app.toast (_("Removed from favorites"));
        });
        network.queue (msg);
    }

    public void set_muted (bool mute = true) {
        var action = mute ? "mute" : "unmute";
        var msg = new Soup.Message ("POST", "%s/api/v1/statuses/%lld/%s".printf (accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            muted = mute;
            updated ();
            if (mute)
                app.toast (_("Muted!"));
            else
                app.toast (_("Conversation unmuted"));
        });
        network.queue (msg);
    }

    public void set_pinned (bool pin = true) {
        var action = pin ? "pin" : "unpin";
        var msg = new Soup.Message ("POST", "%s/api/v1/statuses/%lld/%s".printf (accounts.formal.instance, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            pinned = pin;
            updated ();
            if (pin)
                app.toast (_("Pinned!"));
            else
                app.toast (_("Unpinned from profile"));
        });
        network.queue (msg);
    }

    public Soup.Message poof (bool show_toast = true) {
        var msg = new Soup.Message ("DELETE", "%s/api/v1/statuses/%lld".printf (accounts.formal.instance, id));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            if (show_toast)
                app.toast (_("Poof!"));
            network.status_removed (id);
        });
        network.queue (msg);
        return msg;
    }

}
