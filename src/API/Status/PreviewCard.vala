public class Tuba.API.PreviewCard : Entity {
	public string url { get; set; }
	public string title { get; set; default=""; }
	public string description { get; set; default=""; }
	public string kind { get; set; default="link"; }
	public string author_name { get; set; default=""; }
	public string author_url { get; set; default=""; }
	public string provider_name { get; set; default=""; }
	public string provider_url { get; set; default=""; }
	public string? image { get; set; default=null; }

    public bool is_peertube {
        get { return kind == "video" && provider_name == "PeerTube"; }
    }
}
