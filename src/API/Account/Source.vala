public class Tuba.API.AccountSource : Entity {
	public string language { get; set; default = ""; }
	public string note { get; set; default = ""; }
	public Gee.ArrayList<API.AccountField>? fields { get; set; default=null; }
}
