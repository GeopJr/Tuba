public class Tootle.Status{

    public int64 id;
    public string uri;
    public string url;
    public string content;
    public int64 reblogs_count;
    public int64 favourites_count;
    
    public string avatar;
    public string acct;

    enum Visibility {
        PUBLIC,
        UNLISTED,
        PRIVATE,
        DIRECT;

        public string to_string() {
            switch (this) {
                case PUBLIC:
                    return "public";
                case UNLISTED:
                    return "unlisted";
                case PRIVATE:
                    return "private";
                case DIRECT:
                    return "direct";
                default:
                    assert_not_reached();
            }
        }
    }

    public Status(int64 id) {
        this.id = id;
    }

    public static string escape_html(string content){
        //debug(content);
        return content
        .replace("<br>", "\n")
        .replace("</br>", "")
        .replace("<br />", "\n")
        .replace("rel=\"tag\"", "")
        .replace("rel=\"nofollow noopener\"", "")
        .replace("class=\"mention hashtag\"", "")
        .replace("class=\"h-card\"", "")
        .replace("class=\"invisible\"", "")
        .replace("class=\"ellipsis\"", "")
        .replace("class=\"u-url mention\"", "")
        .replace("class=\"\"", "")
        .replace("<p>", "")
        .replace("</p>", " ")
        .replace("target=\"_blank\"", "");
    }

    public static Status parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var status = new Status (id);
        
        status.uri = obj.get_string_member ("uri");
        status.url = obj.get_string_member ("url");
        status.reblogs_count = obj.get_int_member ("reblogs_count");
        status.favourites_count = obj.get_int_member ("favourites_count");
        status.content = escape_html ( obj.get_string_member ("content"));
        
        var acc = obj.get_object_member ("account");
        status.avatar = acc.get_string_member ("avatar");
        status.acct = acc.get_string_member ("acct");
        
        return status;
    }

}
