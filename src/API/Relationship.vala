public class Tootle.API.Relationship : Entity {

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
		var rs = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
		patch (rs);
		invalidated ();
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
