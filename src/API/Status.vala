public class Tootle.Status {

    public abstract signal void updated ();

    public Account account;
    public int64 id;
    public string uri;
    public string url;
    public string? spoiler_text;
    public string content;
    public int64 reblogs_count;
    public int64 favourites_count;
    public string created_at;    
    public bool reblogged;
    public bool favorited;
    public bool sensitive;
    public StatusVisibility visibility;
    public Status? reblog;
    public Mention[]? mentions;
    public Tag[]? tags;
    public Attachment[]? attachments;

    public Status(int64 id) {
        this.id = id;
        this.reblogged = false;
        this.favorited = false;
    }
    
    public Status get_formal (){
        return reblog != null ? reblog : this;
    }

    public static Status parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var status = new Status (id);
        
        status.account = Account.parse (obj.get_object_member ("account"));
        status.uri = obj.get_string_member ("uri");
        status.url = obj.get_string_member ("url");
        status.created_at = obj.get_string_member ("created_at");
        status.reblogs_count = obj.get_int_member ("reblogs_count");
        status.favourites_count = obj.get_int_member ("favourites_count");
        status.content = Utils.simplify_html ( obj.get_string_member ("content"));
        status.sensitive = obj.get_boolean_member ("sensitive");
        status.visibility = StatusVisibility.from_string (obj.get_string_member ("visibility"));
        
        var spoiler = obj.get_string_member ("spoiler_text");
        if (spoiler != "")
            status.spoiler_text = Utils.simplify_html (spoiler);
        
        if(obj.has_member ("reblogged"))
            status.reblogged = obj.get_boolean_member ("reblogged");
        if(obj.has_member ("favourited"))
            status.favorited = obj.get_boolean_member ("favourited");
            
        if(obj.has_member ("reblog") && obj.get_null_member("reblog") != true)
            status.reblog = Status.parse (obj.get_object_member ("reblog"));
        
        Mention[]? _mentions = {};
        obj.get_array_member ("mentions").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _mentions += Mention.parse (object);
        });
        if (_mentions.length > 0)
            status.mentions = _mentions;
        
        Tag[]? _tags = {};
        obj.get_array_member ("tags").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _tags += Tag.parse (object);
        });
        if (_tags.length > 0)
            status.tags = _tags;
        
        Attachment[]? _attachments = {};
        obj.get_array_member ("media_attachments").foreach_element ((array, i, node) => {
            var object = node.get_object ();
            if (object != null)
                _attachments += Attachment.parse (object);
        });
        if (_attachments.length > 0)
            status.attachments = _attachments;
        
        return status;
    }
    
    public bool is_owned (){
        return get_formal ().account.id == Tootle.accounts.current.id;
    }
    
    public void set_reblogged (bool rebl = true){
        var action = rebl ? "reblog" : "unreblog";
        var msg = new Soup.Message("POST", "%s/api/v1/statuses/%lld/%s".printf (Tootle.settings.instance_url, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            reblogged = rebl;
            updated ();
            if(rebl)
                Tootle.app.toast (_("Boosted!"));
            else
                Tootle.app.toast (_("Removed boost"));
        });
        Tootle.network.queue (msg);
    }
    
    public void set_favorited (bool fav = true){
        var action = fav ? "favourite" : "unfavourite";
        var msg = new Soup.Message("POST", "%s/api/v1/statuses/%lld/%s".printf (Tootle.settings.instance_url, id, action));
        msg.priority = Soup.MessagePriority.HIGH;
        msg.finished.connect (() => {
            favorited = fav;
            updated ();
            if(fav)
                Tootle.app.toast (_("Favorited!"));
            else
                Tootle.app.toast (_("Removed from favorites"));
        });
        Tootle.network.queue (msg);
    }

}
