public class Tuba.HandleProvider: Tuba.CompletionProvider {

	public HandleProvider () {
		Object (trigger_char: "@");
	}

	internal class Proposal: Object, GtkSource.CompletionProposal {
		public API.Account account { construct; get; }

		public Proposal (API.Account entity) {
			Object (account: entity);
		}

		public override string? get_typed_text () {
			return this.account.handle.offset (1) + " ";
		}
	}

	public override async ListModel suggest (GtkSource.CompletionContext context, Cancellable? cancellable) throws Error {
		var word = context.get_word ();

		var req = API.Account.search (word);
		yield req.await ();

		var results = new GLib.ListStore (typeof (Object));
		var parser = Network.get_parser_from_inputstream (req.response_body);
		Network.parse_array (req.msg, parser, node => {
			var entity = Tuba.EntityCache.lookup_or_insert (node, typeof (API.Account));
			if (entity is API.Account) {
				var proposal = new Proposal (entity as API.Account);
				results.append (proposal);
			}
		});

		return results;
	}

	public override void display (
		GtkSource.CompletionContext context,
		GtkSource.CompletionProposal proposal,
		GtkSource.CompletionCell cell
	) {
		var account = (proposal as Proposal)?.account;
		return_if_fail (account != null);

		switch (cell.get_column ()) {
			case GtkSource.CompletionColumn.ICON:
				var avatar = new Adw.Avatar (32, null, true);
				avatar.name = account.display_name;
				Tuba.ImageCache.request_paintable (account.avatar, (is_loaded, paintable) => {
					if (is_loaded)
						avatar.custom_image = paintable;
				});
				cell.set_widget (avatar);
				break;
			case GtkSource.CompletionColumn.TYPED_TEXT:
				cell.set_markup (@"<b>$(account.display_name)</b>\n<span alpha='50%'>$(account.handle)</span>");
				break;
			default:
				cell.text = null;
				break;
		}
	}
}
