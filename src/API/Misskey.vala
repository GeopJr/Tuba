public class Tuba.API.Misskey : Object {
    public class JSON : Object {
        public static string get_app (string callback_url) {
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

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            return generator.to_data (null);
        }

        public static string get_session_generate (string secret) {
            var builder = new Json.Builder ();
            builder.begin_object ();

            builder.set_member_name ("appSecret");
            builder.add_string_value (secret);

            builder.end_object ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            return generator.to_data (null);
        }

        public static string get_session_userkey (string secret, string token) {
            var builder = new Json.Builder ();
            builder.begin_object ();

            builder.set_member_name ("appSecret");
            builder.add_string_value (secret);

            builder.set_member_name ("token");
            builder.add_string_value (token);

            builder.end_object ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            return generator.to_data (null);
        }

        public static string get_show_userid (string userid) {
            var builder = new Json.Builder ();
            builder.begin_object ();

            builder.set_member_name ("userId");
            builder.add_string_value (userid);

            builder.end_object ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            return generator.to_data (null);
        }
    }

    public static string generate_i (string secret, string access_token) {
        string pre_c = @"$access_token$secret";
        Checksum checksum = new Checksum (ChecksumType.SHA256);
    
        checksum.update (pre_c.data, -1);
        return checksum.get_string ();
    }

    public static API.Account to_mastodon_account (Json.Node node) {
        var root = node.get_object ();

        var mk_name = root.get_string_member ("name");
        var mk_username = root.get_string_member ("username");
        var mk_host = root.get_string_member ("host");
        var mk_avatar_url = root.get_string_member ("avatarUrl");
        var mk_description = root.get_string_member ("description");
        var mk_is_locked = root.get_boolean_member ("isLocked");
        var mk_url = root.get_string_member ("url");
        var mk_created_at = root.get_string_member ("createdAt");
        var mk_banner_url = root.get_string_member ("bannerUrl");
        var mk_followers_count = root.get_int_member ("followersCount");
        var mk_following_count = root.get_int_member ("followingCount");
        var mk_notes_count = root.get_int_member ("notesCount");
        // fields
        // pinned

        var masto_acc = new API.Account.empty (root.get_string_member ("id"));
        masto_acc.username = mk_username;
        masto_acc.acct = mk_host != null ? @"$mk_username@$mk_host" : mk_username;
        masto_acc.note = mk_description ?? "";
        masto_acc.locked = mk_is_locked;
        masto_acc.header = mk_banner_url;
        masto_acc.avatar = mk_avatar_url;
        masto_acc.url = mk_url;
        masto_acc.followers_count = mk_followers_count;
        masto_acc.following_count = mk_following_count;
        masto_acc.statuses_count = mk_notes_count;
        masto_acc.created_at = mk_created_at;

        return masto_acc;
    }
}
