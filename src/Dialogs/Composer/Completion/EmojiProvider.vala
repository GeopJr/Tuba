public class Tuba.EmojiProvider: Tuba.CompletionProvider {

	public EmojiProvider () {
		Object (trigger_char: ':');
	}

	internal class Proposal: Object, GtkSource.CompletionProposal {
		public API.Emoji emoji { construct; get; }

		public Proposal (API.Emoji entity) {
			Object (emoji: entity);
		}

		public override string? get_typed_text () {
			return this.emoji.shortcode + ":";
		}
	}

	public override async ListModel suggest (string word, Cancellable? cancellable) throws Error {
		var results = new GLib.ListStore (typeof (Object));
		var emojis = accounts.active.instance_emojis;
		if (emojis == null) return results;

		string new_word = word.offset (1).down ();
		emojis.@foreach (e => {
			if (e.shortcode.down ().index_of (new_word) != 0)
				return true;

			var proposal = new Proposal (e);
			results.append (proposal);

			return results.n_items < 4;
		});

		return results;
	}

	public override void display (
		GtkSource.CompletionContext context,
		GtkSource.CompletionProposal proposal,
		GtkSource.CompletionCell cell
	) {
		var real_proposal = proposal as Proposal;
		if (real_proposal == null) return;

		var emoji = real_proposal.emoji;
		return_if_fail (emoji != null);

		switch (cell.get_column ()) {
			case GtkSource.CompletionColumn.ICON:
				var image = new Gtk.Image () {
					pixel_size = 36
				};
				Tuba.Helper.Image.request_paintable (emoji.url, null, false, (paintable) => {
					image.paintable = paintable;
				});
				cell.set_widget (image);
				break;
			case GtkSource.CompletionColumn.TYPED_TEXT:
				cell.set_markup (":" + proposal.get_typed_text ());
				break;
			default:
				cell.text = null;
				break;
		}
	}

	public override bool word_stop (unichar ch) {
		return base.word_stop (ch) || (!ch.isalnum () && ch != this.trigger_char);
	}
}
