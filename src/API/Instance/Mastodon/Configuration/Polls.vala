public class Tuba.API.Mastodon.Configuration.Polls : Entity {
	public int64 max_options { get; set; }
	public int64 max_characters_per_option { get; set; default = -1; }
	public int64 max_option_chars { get; set; default = -1; }
	public int64 min_expiration { get; set; }
	public int64 max_expiration { get; set; }

	public int64 compat_status_poll_max_characters {
		get {
			return max_characters_per_option != -1 ? max_characters_per_option : max_option_chars;
		}
	}
}
