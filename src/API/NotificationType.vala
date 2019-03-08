public enum Tootle.NotificationType {
    MENTION,
    REBLOG,
    REBLOG_REMOTE_USER, // Internal
    FAVORITE,
    FOLLOW,
    FOLLOW_REQUEST,     // Internal
    WATCHLIST;          // Internal

    public string to_string() {
        switch (this) {
            case MENTION:
                return "mention";
            case REBLOG:
                return "reblog";
            case REBLOG_REMOTE_USER:
                return "reblog_remote";
            case FAVORITE:
                return "favourite";
            case FOLLOW:
                return "follow";
            case FOLLOW_REQUEST:
                return "follow_request";
            case WATCHLIST:
                return "watchlist";
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
            case "reblog_remote":
                return REBLOG_REMOTE_USER;
            case "favourite":
                return FAVORITE;
            case "follow":
                return FOLLOW;
            case "follow_request":
                return FOLLOW_REQUEST;
            case "watchlist":
                return WATCHLIST;
            default:
                assert_not_reached();
        }
    }

    public string get_desc (Account? account) {
        switch (this) {
            case MENTION:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> mentioned you</span>").printf (account.url, account.display_name);
            case REBLOG:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> boosted your toot</span>").printf (account.url, account.display_name);
            case REBLOG_REMOTE_USER:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> boosted</span>").printf (account.url, account.display_name);
            case FAVORITE:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> favorited your toot</span>").printf (account.url, account.display_name);
            case FOLLOW:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> now follows you</span>").printf (account.url, account.display_name);
            case FOLLOW_REQUEST:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> wants to follow you</span>").printf (account.url, account.display_name);
            case WATCHLIST:
                return _("<span underline=\"none\"><a href=\"%s\"><b>%s</b></a> posted a toot</span>").printf (account.url, account.display_name);
            default:
                assert_not_reached();
        }
    }

    public string get_icon () {
        switch (this) {
            case MENTION:
            case WATCHLIST:
                return "user-available-symbolic";
            case REBLOG:
                return "media-playlist-repeat-symbolic";
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
