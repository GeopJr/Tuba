public class Tuba.API.Filters.FilterKeyword : Entity {
	public string id { get; set; }
	public string keyword { get; set; }
	public bool whole_word { get; set; default=true; }
}
