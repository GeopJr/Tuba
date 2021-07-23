using Gtk;
using Gee;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/compose.ui")]
public class Tootle.Dialogs.Compose : Adw.Window {

	public API.Status status { get; construct set; }

	public string button_label {
		set { commit_button.label = value; }
	}
	public string button_class {
		set { commit_button.add_css_class (value); }
	}

	construct {
		transient_for = app.main_window;
		title_switcher.stack = stack;

		notify["status"].connect (() => {
			build ();
			present ();
		});
	}

	protected virtual signal void build () {
		add_page (new EditorPage ());
		add_page (new AttachmentsPage ());
		add_page (new PollPage ());
	}

	[GtkChild] unowned Adw.ViewSwitcherTitle title_switcher;
	[GtkChild] unowned Button commit_button;

	[GtkChild] unowned Adw.ViewStack stack;



	public Compose (API.Status template = new API.Status.empty ()) {
		Object (
			status: template,
			button_label: _("Publish"),
			button_class: "suggested-action"
		);
	}

	public Compose.redraft (API.Status status) {
		Object (
			status: status,
			button_label: _("Redraft"),
			button_class: "destructive-action"
		);
	}

	public Compose.reply (API.Status to) {
		var template = new API.Status.empty () {
			in_reply_to_id = to.id.to_string (),
			in_reply_to_account_id = to.account.id.to_string (),
			spoiler_text = to.spoiler_text,
			content = to.formal.get_reply_mentions ()
		};

		Object (
			status: template,
			button_label: _("Reply"),
			button_class: "suggested-action"
		);
	}

	protected T? get_page<T> () {
		var pages = stack.get_pages ();
		for (var i = 0; i < pages.get_n_items (); i++) {
			var page = pages.get_object (i);
			if (page is T)
				return page;
		}
		return null;
	}

	protected void add_page (ComposerPage page) {
		var wrapper = stack.add (page);
		page.on_build (this, this.status);
		modify_req.connect (page.on_sync);
		modify_req.connect (page.on_modify_req);
		page.bind_property ("visible", wrapper, "visible", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("title", wrapper, "title", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("icon_name", wrapper, "icon_name", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("badge_number", wrapper, "badge_number", GLib.BindingFlags.SYNC_CREATE);
	}

	[GtkCallback] void on_close () {
		destroy ();
	}

	[GtkCallback] void on_commit () {
		//working = true
		transaction.begin ((obj, res) => {
			try {
				transaction.end (res);
				// on_close ();
			}
			catch (Error e) {
				// working = false;
				// on_error (0, e.message);
				warning (e.message);
			}
		});
	}

	protected signal void modify_req (Request req);

	protected virtual async void transaction () throws Error {
		var publish_req = new Request () {
			method = "POST",
			url = "/api/v1/statuses",
			account = accounts.active
		};
		modify_req (publish_req);
		yield publish_req.await ();

		var node = network.parse_node (publish_req);
		var status = API.Status.from (node);
		message (@"Published post with id $(status.id)");

		on_close ();
	}

}
