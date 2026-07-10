public class Tuba.API.SearchResults : Entity {

	public Gee.ArrayList<API.Account> accounts { get; set; }
	public Gee.ArrayList<API.Status> statuses { get; set; }
	public Gee.ArrayList<API.Tag> hashtags { get; set; }
	public Gee.ArrayList<API.Tag>? collections { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "accounts":
				return typeof (API.Account);
			case "statuses":
				return typeof (API.Status);
			case "hashtags":
				return typeof (API.Tag);
			case "collections":
				return typeof (API.Collection);
		}

		return base.deserialize_array_type (prop);
	}

	public static SearchResults from (Json.Node node) throws Error {
		return Entity.from_json (typeof (SearchResults), node) as SearchResults;
	}

	public Entity first () throws Error {
		if (accounts.size > 0)
			return accounts[0];
		else if (statuses.size > 0)
			return statuses[0];
		else if (hashtags.size > 0)
			return hashtags[0];
		else if (collections != null && collections.size > 0)
			return collections[0];
		else
			throw new Oopsie.INTERNAL (_("Search returned no results"));
	}

	public static async SearchResults request (string q, InstanceAccount account) throws Error {
		var req = new RequestV2 ("/api/v2/search") { account = account };
		req.add_parameter ("resolve", "true");
		req.add_parameter ("q", q);

		var in_stream = yield req.exec (null);
		Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
		return from (network.parse_node (parser));
	}
}
