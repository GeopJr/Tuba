public enum Tootle.API.Visibility {
    PUBLIC,
    UNLISTED,
    PRIVATE,
    DIRECT;

    public string to_string () {
        switch (this) {
            case UNLISTED:
                return "unlisted";
            case PRIVATE:
                return "private";
            case DIRECT:
                return "direct";
            default:
                return "public";
        }
    }

    public static Visibility from_string (string str) {
        switch (str) {
            case "unlisted":
                return Visibility.UNLISTED;
            case "private":
                return Visibility.PRIVATE;
            case "direct":
                return Visibility.DIRECT;
            default:
                return Visibility.PUBLIC;
        }
    }

    public string get_name () {
        switch (this) {
            case UNLISTED:
                return _("Unlisted");
            case PRIVATE:
                return _("Followers-only");
            case DIRECT:
                return _("Direct");
            default:
                return _("Public");
        }
    }

    public string get_desc () {
        switch (this) {
            case UNLISTED:
                return _("Don\'t post to public timelines");
            case PRIVATE:
                return _("Post to followers only");
            case DIRECT:
                return _("Post to mentioned users only");
            default:
                return _("Post to public timelines");
        }
    }

    public string get_icon () {
        switch (this) {
            case UNLISTED:
                return "changes-allow-symbolic";
            case PRIVATE:
                return "changes-prevent-symbolic";
            case DIRECT:
                return "user-available-symbolic";
            default:
                return "network-workgroup-symbolic";
        }
    }

    public static Visibility[] all () {
    	return {Visibility.PUBLIC, Visibility.UNLISTED, Visibility.PRIVATE, Visibility.DIRECT};
    }

}
