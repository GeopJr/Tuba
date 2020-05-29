public class Tootle.API.Mention : GLib.Object {

    public int64 id { get; construct set; }
    public string username { get; construct set; }
    public string acct { get; construct set; }
    public string url { get; construct set; }

    public Mention (Json.Object obj) {
    	Object (
    		id: int64.parse (obj.get_string_member ("id")),
    		username: obj.get_string_member ("username"),
    		acct: obj.get_string_member ("acct"),
    		url: obj.get_string_member ("url")
    	);
    }

    public Mention.from_account (Account account) {
    	Object (
    		id: account.id,
    		username: account.username,
    		acct: account.acct,
    		url: account.url
    	);
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("username");
        builder.add_string_value (username);
        builder.set_member_name ("acct");
        builder.add_string_value (acct);
        builder.set_member_name ("url");
        builder.add_string_value (url);
        builder.end_object ();
        return builder.get_root ();
    }

}
