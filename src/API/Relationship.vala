public class Tuba.API.Relationship : Entity {

	public signal void invalidated ();
	public bool tuba_has_loaded { get; set; default=false; }

	public string id { get; set; default = ""; }
	public bool following { get; set; default = false; }
	public bool followed_by { get; set; default = false; }
	public bool showing_reblogs { get; set; default = true; }
	public bool muting { get; set; default = false; }
	public bool muting_notifications { get; set; default = false; }
	public bool requested { get; set; default = false; }
	public bool blocking { get; set; default = false; }
	public bool blocked_by { get; set; default = false; }
	public bool domain_blocking { get; set; default = false; }
	public bool notifying { get; set; default = false; }
	public string? note { get; set; default = null; }

	public string to_string () {
		string label = "";

		if (requested)
			label = _("Sent follow request");
		else if (followed_by && following)
			label = _("Mutuals");
		else if (followed_by)
			label = _("Follows you");
		else if (blocked_by)
			// translators: as in, you've been blocked by them
			label = _("Blocks you");

		return label;
	}

	public Relationship.for_account (API.Account acc) {
		Object (id: acc.id);
		request ();
	}

	public Relationship.for_account_id (string t_id) {
		Object (id: t_id);
		request ();
	}

	public void request () {
		new Request.GET ("/api/v1/accounts/relationships")
			.with_account (accounts.active)
			.with_param ("id", id)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				Network.parse_array (parser, node => {
					invalidate (node);
				});
			})
			.exec ();
	}

	public static async Gee.HashMap<string, API.Relationship> request_many (string[] ids) throws Error {
		Gee.HashMap<string, API.Relationship> res = new Gee.HashMap<string, API.Relationship> ();

		var id_array = Request.array2string (new Gee.ArrayList<string>.wrap (ids), "id");
		var req = new Request.GET (@"/api/v1/accounts/relationships?$id_array")
			.with_account (accounts.active);
		yield req.await ();

		var parser = Network.get_parser_from_inputstream (req.response_body);
		Network.parse_array (parser, node => {
			API.Relationship entity = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
			entity.tuba_has_loaded = true;
			res.set (entity.id, entity);
		});

		return res;
	}

	void invalidate (Json.Node node) throws Error {
		var rs = Entity.from_json (typeof (API.Relationship), node) as API.Relationship;
		patch (rs);
		tuba_has_loaded = true;
		invalidated ();
	}

	public void modify (string operation, string? param = null, string? val = null) {
		var req = new Request.POST (@"/api/v1/accounts/$id/$operation")
			.with_account (accounts.active)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				invalidate (node);
				debug (@"Performed \"$operation\" on Relationship $id");
			});

		if (param != null)
			req.with_param (param, val);

		req.exec ();
	}

	public void modify_note (string comment) {
		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("comment");
		builder.add_string_value (comment);

		builder.end_object ();

		new Request.POST (@"/api/v1/accounts/$id/note")
			.with_account (accounts.active)
			.body_json (builder)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				invalidate (node);
				debug (@"Performed \"note\" on Relationship $id");
			})
			.exec ();
	}

	public void question_modify_block (string handle, bool block = true) {
		var q = block ? _("Block \"%s\"?") : _("Unblock \"%s\"?");

		app.question.begin (
			{q.printf (handle), false},
			null,
			app.main_window,
			{ { block ? _("Block") : _("Unblock"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
			false,
			(obj, res) => {
				if (app.question.end (res).truthy ()) modify (block ? "block" : "unblock");
			}
		);
	}

}
