public class Tuba.API.Application : Entity {
	public Gee.ArrayList<string>? scopes { get; set; default=null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "scopes":
				return Type.STRING;
		}

		return base.deserialize_array_type (prop);
	}

	public async static bool has_push () {
		var msg = new RequestV2 ("/api/v1/apps/verify_credentials") { account = accounts.active };
		try {
			var in_stream = yield msg.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			API.Application? ent = Entity.from_json (typeof (API.Application), network.parse_node (parser)) as API.Application;
			if (ent != null && ent.scopes != null) {
				return "push" in ent.scopes;
			}
		} catch (Error e) {
			warning (@"Couldn't fetch application scopes: $(e.code) $(e.message)");
		}

		// assume true, worst case scenario webpush registration fails
		return true;
	}
}
