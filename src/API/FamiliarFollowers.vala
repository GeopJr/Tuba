public class Tuba.API.FamiliarFollowers : Entity {
	public Gee.ArrayList<API.Account>? accounts { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "accounts":
				return typeof (API.Account);
		}

		return base.deserialize_array_type (prop);
	}
}
