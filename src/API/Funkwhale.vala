public class Tuba.API.Funkwhale : Entity {
	public Gee.ArrayList<API.FunkwhaleTrack>? uploads { get; set; default=null; }

	public static Funkwhale from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Funkwhale), node) as API.Funkwhale;
	}
}
