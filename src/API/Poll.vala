public class Tuba.API.Poll : Entity, Widgetizable {
	public string id { get; set; }
	public string expires_at { get; set; }
	public bool expired { get; set; }
	public bool multiple { get; set; }
	public int64 votes_count { get; set; }
	public bool voted { get; set; default = true;}
	public Gee.ArrayList<int> own_votes { get; set; default = null; }
	public Gee.ArrayList<PollOption>? options { get; set; default = null; }

	public Poll (string _id) {
		id = _id;
	}

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "options":
				return typeof (API.PollOption);
			case "own-votes":
				return Type.INT;
		}

		return base.deserialize_array_type (prop);
	}

	public static Poll from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Poll), node) as API.Poll;
	}

	public override void open () {}

	public static Request vote (
		InstanceAccount acc,
		Gee.ArrayList<PollOption> options,
		Gee.ArrayList<string> selection,
		string id
	) {
		debug (@"Voting poll $(id)…");

		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("choices");
		builder.begin_array ();
		var row_number=0;
		foreach (API.PollOption p in options) {
			foreach (string select in selection) {
				if (select == p.title) {
					builder.add_string_value (row_number.to_string ());
				}
			}
			row_number++;
		}
		builder.end_array ();

		builder.end_object ();

		var generator = new Json.Generator ();
		generator.set_root (builder.get_root ());
		var json = generator.to_data (null);

		Request voting = new Request.POST (@"/api/v1/polls/$(id)/votes")
			.with_account (acc);
		voting.set_request_body_from_bytes ("application/json", new Bytes.take (json.data));
		return voting;
	}
}
