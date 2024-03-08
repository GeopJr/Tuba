public class Tuba.API.AccountSource : Entity {
	public string language { get; set; default = ""; }
	public string note { get; set; default = ""; }
	public int follow_requests_count { get; set; default = 0; }
	public Gee.ArrayList<API.AccountField>? fields { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "fields":
				return typeof (API.AccountField);
		}

		return base.deserialize_array_type (prop);
	}
}
