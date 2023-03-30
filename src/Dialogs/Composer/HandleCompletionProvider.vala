using Gtk;

public class Tuba.HandleCompletionProvider: GLib.Object, GtkSource.CompletionProvider {

	protected GLib.ListStore results = new GLib.ListStore (typeof(Object));
	protected bool is_capturing_input { get; set; default = false; }
	protected int empty_triggers = 0;

	internal class Proposal: Object, GtkSource.CompletionProposal {
		public API.Account account { construct; get; }

		public Proposal (API.Account entity) {
			Object (account: entity);
		}
	}

	public void activate (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal) {
		var account = (proposal as Proposal)?.account;
		return_if_fail (account != null);

		TextIter start;
		TextIter end;
		context.get_bounds (out start, out end);

		var buffer = start.get_buffer ();
		var new_content = account.handle.offset (1) + " ";

		buffer.begin_user_action ();
		buffer.@delete (ref start, ref end);
		buffer.insert_text (ref start, new_content, new_content.length);
		buffer.end_user_action ();

		message ("Stopped capturing input");
		this.is_capturing_input = false;
		this.empty_triggers = 0;
		this.results.remove_all ();
	}

	public bool is_trigger (Gtk.TextIter iter, unichar ch) {
		if (ch.to_string () == "@") {
			message ("Capturing input");
			this.results.remove_all ();
			this.is_capturing_input = true;
			return true;
		}
		return false;
	}

	public async GLib.ListModel populate_async (GtkSource.CompletionContext context, GLib.Cancellable? cancellable) throws GLib.Error {
		if (!this.is_capturing_input) {
			return this.results;
		}

		var word = context.get_word ();
		if (word == "") {
			message ("Empty trigger");
			this.empty_triggers++;

			if (this.empty_triggers > 1) {
				message ("Stopped capturing input");
				this.is_capturing_input = false;
				this.empty_triggers = 0;
				this.results.remove_all ();
			}
			return this.results;
		}

		this.results.remove_all ();

		var req = yield API.Account.search (word);
		yield req.await();

		Network.parse_array (req.msg, req.response_body, node => {
			if (word != context.get_word ())
				return;

			var entity = entity_cache.lookup_or_insert (node, typeof (API.Account));
			if (entity is API.Account) {
				var proposal = new Proposal (entity as API.Account);
				this.results.append (proposal);
			}
		});

		return this.results;
	}

	public void display (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, GtkSource.CompletionCell cell) {
		var account = (proposal as Proposal)?.account;
		return_if_fail (account != null);

		var column = cell.get_column ();
		switch (column) {
			case GtkSource.CompletionColumn.ICON:
				var avatar = new Widgets.Avatar ();
				avatar.account = account;
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

	public void refilter (GtkSource.CompletionContext context, GLib.ListModel model) {
		// no-op
	}

}