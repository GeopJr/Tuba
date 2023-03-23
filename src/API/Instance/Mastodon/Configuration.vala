public class Tuba.API.Mastodon.Configurations : Entity {
	public API.Mastodon.Configuration.Statuses statuses { get; set; }
	public API.Mastodon.Configuration.MediaAttachments media_attachments { get; set; }
	public API.Mastodon.Configuration.Polls polls { get; set; }
	public API.Mastodon.Configuration.Reactions? reactions { get; set; default = null; }
}
