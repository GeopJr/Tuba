public class Tootle.EntityCache : AbstractCache {

	// Must return unique id for each JSON entity node
	protected string? get_node_cache_id (owned Json.Node node) {
		var obj = node.get_object ();
		if (obj.has_member ("uri")) {
			return obj.get_string_member ("uri");
		}

		return null;
	}

	public Entity lookup_or_insert (owned Json.Node node, owned Type type) {
		Entity entity = null;
		var id = get_node_cache_id (node);

		// Entity can't be cached
		if (id == null) {
			entity = Entity.from_json (type, node);
		}
		else {

			// Entity can be reused from cache
			if (contains (id)) {
				entity = lookup (get_key (id)) as Entity;
				message ("Reused: "+id);
			}
			// It's a new instance and we need to store it
			else {
				entity = Entity.from_json (type, node);
				insert (id, entity);
			}
		}

		return entity;
	}

}
