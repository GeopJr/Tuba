public class Tuba.API.StatusSource : Entity {
	public string id { get; set; }
	public string text { get; set; }
	public string spoiler_text { get; set; }

    public static StatusSource from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.StatusSource), node) as API.StatusSource;
	}
}
