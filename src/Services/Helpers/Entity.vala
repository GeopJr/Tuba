public class Tuba.Helper.Entity {
	public static Tuba.Entity from_json (owned Json.Node node, owned Type type, bool force = false) {
		Tuba.Entity entity = null;

		try {
			entity = Tuba.Entity.from_json (type, node);
		} catch (Error e) {
			warning (@"Error getting Entity from json: $(e.message)");
		}

		return entity;
	}
}
