public class Tuba.API.Filters.FilterResult : Entity {
	public Filter filter { get; set; }
	public Gee.ArrayList<string>? keyword_matches { get; set; default=null; }
	public Gee.ArrayList<string>? status_matches { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "keyword-matches":
			case "status-matches":
				return Type.STRING;
		}

		return base.deserialize_array_type (prop);
	}
}
