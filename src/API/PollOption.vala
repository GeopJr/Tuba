public class Tuba.API.PollOption : Entity {
	public string? title { get; set; }
	public int64 votes_count { get; set; default=0; }
	public string? tuba_translated_title { get; set; default = null; }
}
