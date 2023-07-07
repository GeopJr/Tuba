public class Tuba.API.Misskey.JSON : Object {
    public static Json.Builder get_app (string callback_url) {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("name");
        builder.add_string_value (Build.NAME);

        builder.set_member_name ("description");
        builder.add_string_value ("Browse the Fediverse");

        builder.set_member_name ("permission");
        builder.begin_array ();
        builder.add_string_value ("write:user-groups");
        builder.add_string_value ("read:user-groups");
        builder.add_string_value ("read:page-likes");
        builder.add_string_value ("write:page-likes");
        builder.add_string_value ("write:pages");
        builder.add_string_value ("read:pages");
        builder.add_string_value ("write:votes");
        builder.add_string_value ("write:reactions");
        builder.add_string_value ("read:reactions");
        builder.add_string_value ("write:notifications");
        builder.add_string_value ("read:notifications");
        builder.add_string_value ("write:notes");
        builder.add_string_value ("write:mutes");
        builder.add_string_value ("read:mutes");
        builder.add_string_value ("read:account");
        builder.add_string_value ("write:account");
        builder.add_string_value ("read:blocks");
        builder.add_string_value ("write:blocks");
        builder.add_string_value ("read:drive");
        builder.add_string_value ("write:drive");
        builder.add_string_value ("read:favorites");
        builder.add_string_value ("write:favorites");
        builder.add_string_value ("read:following");
        builder.add_string_value ("write:following");
        builder.add_string_value ("read:messaging");
        builder.add_string_value ("write:messaging");
        builder.end_array ();

        builder.set_member_name ("callbackUrl");
        builder.add_string_value (callback_url);

        builder.end_object ();

        return builder;
    }

    public static Json.Builder get_session_generate (string secret) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("appSecret");
        builder.add_string_value (secret);

        builder.end_object ();

        return builder;
    }

    public static Json.Builder get_session_userkey (string secret, string token) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("appSecret");
        builder.add_string_value (secret);

        builder.set_member_name ("token");
        builder.add_string_value (token);

        builder.end_object ();

        return builder;
    }

    public static Json.Builder get_show_userid (string userid) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("userId");
        builder.add_string_value (userid);

        builder.end_object ();

        return builder;
    }

    public static Json.Builder get_timeline (int limit = 20, string? userId = null) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        //  builder.set_member_name ("i");
        //  builder.add_string_value (accounts.active.i);

        builder.set_member_name ("limit");
        builder.add_int_value (limit);

        if (userId != null) {
            builder.set_member_name ("userId");
            builder.add_string_value (userId);
        }

        builder.end_object ();

        return builder;
    }

    public static Json.Builder get_children (string noteId) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        //  builder.set_member_name ("limit");
        //  builder.add_int_value (limit);

        builder.set_member_name ("noteId");
        builder.add_string_value (noteId);

        builder.end_object ();

        return builder;
    }

    public static Json.Builder get_delete_note (string noteId) {
        var builder = new Json.Builder ();
        builder.begin_object ();

        builder.set_member_name ("noteId");
        builder.add_string_value (noteId);

        builder.end_object ();

        return builder;
    }
}

public class Tuba.API.Misskey.Utils : Object {
    public static string generate_i (string secret, string access_token) {
        string pre_c = @"$access_token$secret";
        Checksum checksum = new Checksum (ChecksumType.SHA256);

        checksum.update (pre_c.data, -1);
        return checksum.get_string ();
    }
}
