public class Tootle.API.Relationship : GLib.Object {

    public int64 id { get; construct set; }
    public bool following { get; set; default = false; }
    public bool followed_by { get; set; default = false; }
    public bool muting { get; set; default = false; }
    public bool muting_notifications { get; set; default = false; }
    public bool requested { get; set; default = false; }
    public bool blocking { get; set; default = false; }
    public bool domain_blocking { get; set; default = false; }

    public Relationship (Json.Object obj) {
    	Object (
    		id: int64.parse (obj.get_string_member ("id")),
    		following: obj.get_boolean_member ("following"),
    		followed_by: obj.get_boolean_member ("followed_by"),
    		blocking: obj.get_boolean_member ("blocking"),
    		muting: obj.get_boolean_member ("muting"),
    		muting_notifications: obj.get_boolean_member ("muting_notifications"),
    		requested: obj.get_boolean_member ("requested"),
    		domain_blocking: obj.get_boolean_member ("domain_blocking")
    	);
    }

}
