public class Tootle.API.Attachment : GLib.Object {

    public int64 id { get; construct set; }
    public string kind { get; set; }
    public string url { get; set; }
    public string? description { get; set; default = null; }

    public string? _preview_url = null;
    public string preview_url {
        set { this._preview_url = value; }
    	get { return (_preview_url == null || _preview_url == "") ? url : _preview_url; }
    }

    public Attachment (Json.Object obj) {
        Object (
            id: int64.parse (obj.get_string_member ("id")),
            kind: obj.get_string_member ("type"),
            preview_url: obj.get_string_member ("preview_url"),
            url: obj.get_string_member ("url"),
            description: obj.get_string_member ("description")
        );
    }

    public Json.Node? serialize () {
        var builder = new Json.Builder ();
        builder.begin_object ();
        builder.set_member_name ("id");
        builder.add_string_value (id.to_string ());
        builder.set_member_name ("type");
        builder.add_string_value (kind);
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
