public class Tuba.API.BookWyrmAuthor : Entity {
	public string id { get; set; default=""; }
	public string openlibraryKey { get; set; default=""; }
	public string name { get; set; default=""; }

    public static BookWyrmAuthor from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.BookWyrmAuthor), node) as API.BookWyrmAuthor;
	}
}
