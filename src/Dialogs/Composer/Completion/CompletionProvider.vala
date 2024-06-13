public abstract class Tuba.CompletionProvider: Object, GtkSource.CompletionProvider {

	public static GLib.ListStore EMPTY = new GLib.ListStore (typeof (Object)); // vala-lint=naming-convention

	public unichar trigger_char { get; set; }
	protected bool is_capturing_input { get; set; default = false; }

	public virtual bool is_trigger (Gtk.TextIter iter, unichar ch) {
		return this.set_input_capture (ch == this.trigger_char);
	}

	protected bool set_input_capture (bool state) {
		this.is_capturing_input = state;
		if (state) {
			debug ("Capturing input");
		}
		return state;
	}

	public virtual void refilter (GtkSource.CompletionContext context, GLib.ListModel model) {
		// no-op
	}

	public virtual void activate (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal) {
		Gtk.TextIter start;
		Gtk.TextIter end;
		get_whole_word_iters (context, out start, out end);

		var buffer = start.get_buffer ();
		var new_content = get_formatted_text (proposal) + " ";

		buffer.begin_user_action ();
		buffer.@delete (ref start, ref end);
		buffer.insert_text (ref start, new_content, new_content.length);
		buffer.end_user_action ();

		this.set_input_capture (false);
	}

	public async GLib.ListModel populate_async (
		GtkSource.CompletionContext context,
		GLib.Cancellable? cancellable
	) throws Error {
		Gtk.TextIter start;
		Gtk.TextIter end;
		get_whole_word_iters (context, out start, out end);
		is_trigger (start, start.get_char ());
		if (!this.is_capturing_input) return EMPTY;

		string word = start.get_text (end);
		if (word == "") {
			debug ("Empty trigger");
			this.set_input_capture (false);
			return EMPTY;
		}

		return yield this.suggest (word, cancellable);
	}

	public abstract void display (
		GtkSource.CompletionContext context,
		GtkSource.CompletionProposal proposal,
		GtkSource.CompletionCell cell
	);

	public abstract async GLib.ListModel suggest (
		string word,
		GLib.Cancellable? cancellable
	) throws Error;

	public string get_whole_word (GtkSource.CompletionContext context) {
		Gtk.TextIter start;
		Gtk.TextIter end;
		get_whole_word_iters (context, out start, out end);

		return start.get_text (end);
	}

	public void get_whole_word_iters (GtkSource.CompletionContext context, out Gtk.TextIter start, out Gtk.TextIter end) {
		context.get_bounds (out start, out end);

		if (start.backward_find_char (word_stop, null) && start.get_char ().isspace ()) {
			start.forward_char ();
		}

		end.backward_char ();
		end.forward_find_char (word_stop, null);
	}

	public virtual bool word_stop (unichar ch) {
		return ch.isspace ();
	}

	public virtual string get_formatted_text (GtkSource.CompletionProposal proposal) {
		return this.trigger_char.to_string () + proposal.get_typed_text ();
	}
}
