public class Tooth.API.Mastodon.Configuration.Statuses : Entity {
	public int64 max_characters { get; set; }
	public int64 max_media_attachments { get; set; }
	public int64 characters_reserved_per_url { get; set; default = 0; }
}
