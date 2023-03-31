using Gtk;

public class Tuba.HashtagProvider: Tuba.CompletionProvider {

	public HashtagProvider () {
		Object(trigger_char: "#");
	}

	internal class Proposal: Object, GtkSource.CompletionProposal {
		public API.Tag tag { construct; get; }

		public Proposal (API.Tag entity) {
			Object (tag: entity);
		}

		public override string? get_typed_text() {
			return this.tag.name + " ";
		}
	}

	public override async ListModel suggest (GtkSource.CompletionContext context, Cancellable? cancellable) throws Error {
		var word = context.get_word ();

		var req = API.Tag.search (word);
		yield req.await();

		if (word != context.get_word ())
			return EMPTY;

		var results = new GLib.ListStore (typeof (Object));
		var response = API.SearchResults.from (network.parse_node (req.response_body));
		warning (response.hashtags.size.to_string ());
		response.hashtags.foreach (tag => {
			var proposal = new Proposal (tag);
			results.append (proposal);
			return true;
		});

		return results;
	}

	public override void display (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, GtkSource.CompletionCell cell) {
		switch (cell.get_column ()) {
			case GtkSource.CompletionColumn.ICON:
				cell.set_icon_name ("tuba-hashtag-symbolic");
				break;
			case GtkSource.CompletionColumn.TYPED_TEXT:
				cell.set_text (proposal.get_typed_text ());
				break;
			default:
				cell.text = null;
				break;
		}
	}

}