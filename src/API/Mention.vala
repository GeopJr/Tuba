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
		open_real.begin ();
	}

	private async void open_real () {
		var req = new RequestV2 (@"/api/v1/accounts/$id") { account = accounts.active };

		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			var node = network.parse_node (parser);
			API.Account.from (node).open ();
		} catch (GLib.IOError.CANCELLED e) {
			debug ("Message is cancelled.");
		} catch (Error e) {
			warning (@"Error while opening mention: $(e.code) $(e.message)");

			var dlg = app.inform (_("Error"), e.message);
			dlg.present (app.main_window);
		}
	}
}
