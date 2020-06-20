public class Tootle.API.Tag : Entity {

    public string name { get; set; }
    public string url { get; set; }

	public static Tag from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Tag), node) as API.Tag;
	}

}
