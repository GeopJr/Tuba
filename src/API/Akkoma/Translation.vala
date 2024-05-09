public class Tuba.API.AkkomaTranslation : Entity {
	public string text { get; set; default = ""; }
	public string detected_language { get; set; default = ""; }

	public static AkkomaTranslation from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.AkkomaTranslation), node) as API.AkkomaTranslation;
	}
}
