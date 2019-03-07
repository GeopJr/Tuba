public class Tootle.Attachment {

    public int64 id;
    public string type;
    public string url;
    public string preview_url;
    public string? description;

    public Attachment(int64 _id) {
        id = _id;
    }

    public static Attachment parse (Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var attachment = new Attachment (id);

        attachment.type = obj.get_string_member ("type");
        attachment.preview_url = obj.get_string_member ("preview_url");
        attachment.url = obj.get_string_member ("url");

        if (obj.has_member ("description"))
            attachment.description = obj.get_string_member ("description");

        return attachment;
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("type");
        builder.add_string_value (type);
        builder.set_member_name ("url");
        builder.add_string_value (url);
        builder.set_member_name ("preview_url");
        builder.add_string_value (preview_url);

        if (description != null) {
            builder.set_member_name ("description");
            builder.add_string_value (description);
        }

        builder.end_object ();
        return builder.get_root ();
    }

}
