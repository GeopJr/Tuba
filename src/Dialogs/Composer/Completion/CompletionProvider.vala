public abstract class Tuba.CompletionProvider: Object, GtkSource.CompletionProvider {

	public static GLib.ListStore EMPTY = new GLib.ListStore (typeof (Object)); // vala-lint=naming-convention

	public string? trigger_char { get; construct; }
	protected bool is_capturing_input { get; set; default = false; }
	protected int empty_triggers = 0;

	public virtual bool is_trigger (Gtk.TextIter iter, unichar ch) {
		if (this.trigger_char == null) {
			return this.set_input_capture (true);
		}
		else if (ch.to_string () == this.trigger_char) {
			return this.set_input_capture (true);
		}
		return false;
	}

	protected bool set_input_capture (bool state) {
		this.is_capturing_input = state;
		if (state) {
			message ("Capturing input");
		}
		else {
			message ("Stopped capturing input");
			this.empty_triggers = 0;
		}
		return state;
	}

	public virtual void refilter (GtkSource.CompletionContext context, GLib.ListModel model) {
		// no-op
	}

	public virtual void activate (GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal) {
		Gtk.TextIter start;
		Gtk.TextIter end;
		context.get_bounds (out start, out end);

		var buffer = start.get_buffer ();
		var new_content = proposal.get_typed_text ();

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
		if (!this.is_capturing_input) {
			// If it's not capturing,
			// check if the character before the word
			// is the trigger
			Gtk.TextIter start;
			context.get_bounds (out start, null);
			if (start.backward_char ())
				is_trigger (start, start.get_char ());

			return EMPTY;
		}

		var word = context.get_word ();
		if (word == "") {
			message ("Empty trigger");
			this.empty_triggers++;

			if (this.empty_triggers > 1) {
				this.set_input_capture (false);
			}
			return EMPTY;
		}

		var suggestions = yield this.suggest (context, cancellable);

		if (word != context.get_word ())
			return EMPTY;
		return suggestions;
	}

	public abstract void display (
		GtkSource.CompletionContext context,
		GtkSource.CompletionProposal proposal,
		GtkSource.CompletionCell cell
	);

	public abstract async GLib.ListModel suggest (
		GtkSource.CompletionContext context,
		GLib.Cancellable? cancellable
	) throws Error;
}
