public enum Tootle.NotificationType {
    MENTION,
    REBLOG,
    FAVORITE,
    FOLLOW,
    FOLLOW_REQUEST;

    public string to_string() {
        switch (this) {
            case MENTION:
                return "mention";
            case REBLOG:
                return "reblog";
            case FAVORITE:
                return "favourite";
            case FOLLOW:
                return "follow";
            case FOLLOW_REQUEST:
                return "follow_request";
            default:
                assert_not_reached();
        }
    }
    
    public static NotificationType from_string (string str) {
        switch (str) {
            case "mention":
                return MENTION;
            case "reblog":
                return REBLOG;
            case "favourite":
                return FAVORITE;
            case "follow":
                return FOLLOW;
            case "follow_request":
                return FOLLOW_REQUEST;
            default:
                assert_not_reached();
        }
    }
        
    public string get_desc (Account? account) {
        switch (this) {
            case MENTION:
                return _("<a href=\"%s\"><b>%s</b></a> mentioned you").printf (account.url, account.display_name);
            case REBLOG:
                return _("<a href=\"%s\"><b>%s</b></a> boosted your toot").printf (account.url, account.display_name);
            case FAVORITE:
                return _("<a href=\"%s\"><b>%s</b></a> favorited your toot").printf (account.url, account.display_name);
            case FOLLOW:
                return _("<a href=\"%s\"><b>%s</b></a> now follows you").printf (account.url, account.display_name);
            case FOLLOW_REQUEST:
                return _("<a href=\"%s\"><b>%s</b></a> wants to follow you").printf (account.url, account.display_name);
            default:
                assert_not_reached();
        }
    }
        
    public string get_icon () {
        switch (this) {
            case MENTION:
                return "user-available-symbolic";
            case REBLOG:
                return "go-up-symbolic";
            case FAVORITE:
                return "help-about-symbolic";
            case FOLLOW:
            case FOLLOW_REQUEST:
                return "contact-new-symbolic";
            default:
                assert_not_reached();
        }
    }
    
}
