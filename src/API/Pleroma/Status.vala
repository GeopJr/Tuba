public class Tuba.API.Pleroma.Status : Entity {
	public Gee.ArrayList<API.EmojiReaction>? emoji_reactions { get; set; default = null; }
	//  public bool local { get; set; default = false; } // doesn't seem accurate :/

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "emoji-reactions":
				return typeof (API.EmojiReaction);
		}

		return base.deserialize_array_type (prop);
	}
}
