public class Tootle.API.Relationship : Entity {

    public string id { get; set; }
    public bool following { get; set; default = false; }
    public bool followed_by { get; set; default = false; }
    public bool muting { get; set; default = false; }
    public bool muting_notifications { get; set; default = false; }
    public bool requested { get; set; default = false; }
    public bool blocking { get; set; default = false; }
    public bool domain_blocking { get; set; default = false; }

	public static Relationship from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
	}

}
