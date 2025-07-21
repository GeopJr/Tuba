public class Tuba.API.Mention : Entity, Widgetizable {

	public string id { get; construct set; }
	public string username { get; construct set; }
	public string acct { get; construct set; }
	public string url { get; construct set; }

	public string handle {
		owned get {
			return "@" + acct;
		}
	}

	public Mention.from_account (API.Account account) {
		Object (
			id: account.id,
			username: account.username,
			acct: account.acct,
			url: account.url
		);
	}

	public override void open () {
		new Request.GET (@"/api/v1/accounts/$id")
			.with_account (accounts.active)
			.then ((in_stream) => {
				Network.get_parser_from_inputstream_async.begin (in_stream, (obj, res) => {
					try {
						var parser = Network.get_parser_from_inputstream_async.end (res);
						var node = network.parse_node (parser);
						API.Account.from (node).open ();
					} catch (Error e) {
						critical (@"Couldn't parse json: $(e.code) $(e.message)");
					}
				});
			})
			.exec ();
	}

}
