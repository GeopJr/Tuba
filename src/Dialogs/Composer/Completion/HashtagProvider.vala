public class Tuba.HashtagProvider: Tuba.CompletionProvider {

	public HashtagProvider () {
		Object (trigger_char: '#');
	}

	internal class Proposal: Object, GtkSource.CompletionProposal {
		public API.Tag tag { construct; get; }

		public Proposal (API.Tag entity) {
			Object (tag: entity);
		}

		public override string? get_typed_text () {
			return this.tag.name;
		}
	}

	public override async ListModel suggest (string word, Cancellable? cancellable) throws Error {
		var req = API.Tag.search (word.substring (1));
		yield req.await ();

		var suggestions = new GLib.ListStore (typeof (Object));
		var parser = yield Network.get_parser_from_inputstream_async (req.response_body);
		var results = API.SearchResults.from (network.parse_node (parser));
		if (results != null) {
			results.hashtags.foreach (tag => {
				var proposal = new Proposal (tag);
				suggestions.append (proposal);
				return true;
			});
		}

		return suggestions;
	}

	public override void display (
		GtkSource.CompletionContext context,
		GtkSource.CompletionProposal proposal,
		GtkSource.CompletionCell cell
	) {
		var real_proposal = proposal as Proposal;
		if (real_proposal == null) return;

		var tag = real_proposal.tag;
		return_if_fail (tag != null);

		switch (cell.get_column ()) {
			case GtkSource.CompletionColumn.ICON:
				cell.set_widget (new Gtk.Image.from_icon_name ("tuba-hashtag-symbolic") {
					pixel_size = 24
				});
				break;
			case GtkSource.CompletionColumn.TYPED_TEXT:
				cell.set_markup (@"<b>$(tag.name)</b>\n<span alpha='50%'>$(tag.weekly_use ())</span>");
				break;
			default:
				cell.text = null;
				break;
		}
	}
}
