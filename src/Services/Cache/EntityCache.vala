public class Tuba.EntityCache {
	// Must return unique id for each JSON entity node
	protected string? get_node_cache_id (owned Json.Node node) {
		var obj = node.get_object ();
		if (obj.has_member ("uri")) {
			return obj.get_string_member ("uri");
		}

		return null;
	}

	public static Entity lookup_or_insert (owned Json.Node node, owned Type type, bool force = false) {
		Entity entity = null;
		//  var id = get_node_cache_id (node);

		try {
			entity = Entity.from_json (type, node);
		} catch (Error e) {
			warning (@"Error getting Entity from json: $(e.message)");
		}

		return entity;
	}
}
