public class Tuba.EmojiProvider: Tuba.CompletionProvider {

	public EmojiProvider () {
		Object (trigger_char: ":");
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

	public override async ListModel suggest (GtkSource.CompletionContext context, Cancellable? cancellable) throws Error {
		var word = context.get_word ();

		var results = new GLib.ListStore (typeof (Object));
		var emojis = accounts.active.instance_emojis;

		if (emojis == null) return results;
		emojis.@foreach (e => {
			if (e.shortcode.index_of (word) != 0)
				return true;

			var proposal = new Proposal (e);
			results.append (proposal);
			return true;
		});

		return results;
	}

	public override void display (
		GtkSource.CompletionContext context,
		GtkSource.CompletionProposal proposal,
		GtkSource.CompletionCell cell
	) {
		var emoji = (proposal as Proposal)?.emoji;
		return_if_fail (emoji != null);

		switch (cell.get_column ()) {
			case GtkSource.CompletionColumn.ICON:
				var image = new Gtk.Image ();
				Tuba.ImageCache.request_paintable (emoji.url, (is_loaded, paintable) => {
					if (is_loaded)
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
}
