public class Tuba.API.EmojiReaction : Entity {
	public int64 count { get; set; default = 0;}
	public string? url { get; set; default = null; }
	public string? name { get; set; default = null; }
	public bool me { get; set; default = false; }
	public Gee.ArrayList<API.Account>? accounts { get; set; default = null; }
	public Gee.ArrayList<string>? account_ids { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "accounts":
				return typeof (API.Account);
			case "account-ids":
				return Type.STRING;
		}

		return base.deserialize_array_type (prop);
	}
}
