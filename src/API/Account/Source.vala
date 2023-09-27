public class Tuba.API.AccountSource : Entity {
	public string language { get; set; default = ""; }
	public string note { get; set; default = ""; }
	public Gee.ArrayList<API.AccountField>? fields { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		if (prop == "fields") {
			return typeof (API.AccountField);
		}

		return base.deserialize_array_type (prop);
	}
}
