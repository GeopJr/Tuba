public class Tooth.API.EmojiReaction : Entity {
	public int64 count { get; set; default = 0;}
	public string? url { get; set; default = null; }
	public string? name { get; set; default = null; }
	public bool me { get; set; default = false; }
}
