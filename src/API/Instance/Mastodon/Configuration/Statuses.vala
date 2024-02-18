public class Tuba.API.Mastodon.Configuration.Statuses : Entity {
	public int64 max_characters { get; set; }
	public int64 max_media_attachments { get; set; }
	public int characters_reserved_per_url { get; set; default = 0; }
	public string[]? supported_mime_types { get; set; default = null; }
}
