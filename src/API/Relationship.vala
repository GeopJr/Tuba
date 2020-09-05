public class Tootle.API.Relationship : Entity {

	public string id { get; set; default = ""; }
	public bool following { get; set; default = false; }
	public bool followed_by { get; set; default = false; }
	public bool showing_reblogs { get; set; default = true; }
	public bool muting { get; set; default = false; }
	public bool muting_notifications { get; set; default = false; }
	public bool requested { get; set; default = false; }
	public bool blocking { get; set; default = false; }
	public bool domain_blocking { get; set; default = false; }

	public static Relationship from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
	}

	public Relationship.for_account (API.Account acc) {
		Object (id: acc.id);
		request ();
	}

	public void request () {
		new Request.GET ("/api/v1/accounts/relationships")
			.with_account (accounts.active)
			.with_param ("id", id)
			.then ((sess, msg) => {
				Network.parse_array (msg, node => {
					invalidate (node);
				});
			})
			.exec ();
	}

	void invalidate (Json.Node node) throws Error {
		var rs = Relationship.from (node);
		patch (rs);
		notify_property ("id");
	}

	public void modify (string operation, string? param = null, string? val = null) {
		var req = new Request.POST (@"/api/v1/accounts/$id/$operation")
			.with_account (accounts.active)
			.then ((sess, msg) => {
				var node = network.parse_node (msg);
				invalidate (node);
				message (@"Performed \"$operation\" on Relationship $id");
			});

		if (param != null)
			req.with_param (param, val);

		req.exec ();
	}

}
