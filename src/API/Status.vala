public class Tootle.Status{

    public Account account;
    public int64 id;
    public string uri;
    public string url;
    public string? spoiler_text;
    public string content;
    public int64 reblogs_count;
    public int64 favourites_count;
    public string avatar;
    public string acct;
    
    public bool reblogged;
    public bool favorited;
    public Status? reblog;

    public Status(int64 id) {
        this.id = id;
        this.reblogged = false;
        this.favorited = false;
    }

    public static Status parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var status = new Status (id);
        
        status.account = Account.parse(obj.get_object_member ("account"));
        status.uri = obj.get_string_member ("uri");
        status.url = obj.get_string_member ("url");
        status.reblogs_count = obj.get_int_member ("reblogs_count");
        status.favourites_count = obj.get_int_member ("favourites_count");
        status.content = Utils.escape_html ( obj.get_string_member ("content"));
        var spoiler = obj.get_string_member ("spoiler_text");
        if (spoiler != "")
            status.spoiler_text = Utils.escape_html (spoiler);
        
        if(obj.has_member ("reblogged"))
            status.reblogged = obj.get_boolean_member ("reblogged");
        if(obj.has_member ("favourited"))
            status.favorited = obj.get_boolean_member ("favourited");
            
        if(obj.has_member ("reblog") && obj.get_null_member("reblog") != true)
            status.reblog = Status.parse (obj.get_object_member ("reblog"));
        
        return status;
    }

}
