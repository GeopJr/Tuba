public class Tuba.API.Pleroma.Status : Entity {
	public Gee.ArrayList<API.EmojiReaction>? emoji_reactions { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		if (prop == "emoji-reactions") {
			return typeof (API.EmojiReaction);
		}

		return base.deserialize_array_type (prop);
	}
}
