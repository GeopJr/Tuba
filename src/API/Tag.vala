public class Tootle.API.Tag : GLib.Object {

    public string name { get; construct set; }
    public string url { get; construct set; }

    public Tag (Json.Object obj) {
    	Object (
    		name: obj.get_string_member ("name"),
    		url: obj.get_string_member ("url")
    	);
    }

}
