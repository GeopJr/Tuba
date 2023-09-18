public class Tuba.API.Relationship : Entity {

	public signal void invalidated ();

	public string id { get; set; default = ""; }
	public bool following { get; set; default = false; }
	public bool followed_by { get; set; default = false; }
	public bool showing_reblogs { get; set; default = true; }
	public bool muting { get; set; default = false; }
	public bool muting_notifications { get; set; default = false; }
	public bool requested { get; set; default = false; }
	public bool blocking { get; set; default = false; }
	public bool domain_blocking { get; set; default = false; }

	public string to_string () {
		string label = "";

		if (requested)
			label = _("Sent follow request");
		else if (followed_by && following)
			label = _("Mutuals");
		else if (followed_by)
			label = _("Follows you");

		return label;
	}

	public Relationship.for_account (API.Account acc) {
		Object (id: acc.id);
		request ();
	}

	public void request () {
		new Request.GET ("/api/v1/accounts/relationships")
			.with_account (accounts.active)
			.with_param ("id", id)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				Network.parse_array (msg, parser, node => {
					invalidate (node);
				});
			})
			.exec ();
	}

	void invalidate (Json.Node node) throws Error {
		var rs = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
		patch (rs);
		invalidated ();
	}

	public void modify (string operation, string? param = null, string? val = null) {
		var req = new Request.POST (@"/api/v1/accounts/$id/$operation")
			.with_account (accounts.active)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				invalidate (node);
				debug (@"Performed \"$operation\" on Relationship $id");
			});

		if (param != null)
			req.with_param (param, val);

		req.exec ();
	}

}
