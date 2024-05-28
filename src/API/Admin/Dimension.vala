public class Tuba.API.Admin.Dimension : Entity {
	public class Data : Entity {
		public string? key { get; set; default=null; }
		public string? human_key { get; set; default=null; }
		public string? value { get; set; default=null; }
		public string? human_value { get; set; default=null; }
		//  public string? unit { get; set; default=null; }
	}

	public string key { get; set; default=""; }
	public Gee.ArrayList<Data>? data { get; set; default=null; }

	public static Dimension from (Json.Node node) throws Error {
		return Entity.from_json (typeof (Dimension), node) as Dimension;
	}

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "data":
				return typeof (Data);
		}

		return base.deserialize_array_type (prop);
	}
}
