using Gtk;
using Gee;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/compose.ui")]
public class Tuba.Dialogs.Compose : Adw.Window {

	public API.Status status { get; construct set; }

	public delegate void SuccessCallback (API.Status cb_status);
	protected SuccessCallback? cb;

	public string button_label {
		set { commit_button.label = value; }
	}
	public string button_class {
		set { commit_button.add_css_class (value); }
	}
	public bool editing { get; set; default=false; }
	private bool _working = false;
	public bool working {
		get { return _working; }
		set { _working = value; update_commit_button (); update_pages (); }
	}

	ulong build_sigid;

	construct {
		var exit_action = new SimpleAction ("exit", null);
		exit_action.activate.connect (on_exit);

		var action_group = new GLib.SimpleActionGroup ();
		action_group.add_action(exit_action);

		this.insert_action_group ("composer", action_group);
		add_binding_action (Gdk.Key.Escape, 0, "composer.exit", null);
		add_binding_action (Gdk.Key.W, Gdk.ModifierType.CONTROL_MASK, "composer.exit", null);
		add_binding_action (Gdk.Key.Q, Gdk.ModifierType.CONTROL_MASK, "composer.exit", null);

		transient_for = app.main_window;
		title_switcher.stack = stack;

		build_sigid = notify["status"].connect (() => {
			build ();
			present ();

			disconnect (build_sigid);
		});
	}
	~Compose () {
		message ("Destroying composer");
		foreach (var page in t_pages) {
			page.dispose ();
		}
		t_pages = {};
	}

	void on_exit () {
		if (!commit_button.sensitive) on_close ();
	}

	private ComposerPage[] t_pages = {};
	protected virtual signal void build () {
		var p_edit = new EditorPage ();
		var p_attach = new AttachmentsPage ();
		var p_poll = new PollPage ();

		p_edit.ctrl_return_pressed.connect (() => {
			if (commit_button.sensitive) on_commit ();
		});

		setup_pages ({p_edit, p_attach, p_poll});

		// Composer rules
		// 1. Either attachments or polls
		// 2. Poll needs edit to be valid
		p_attach.bind_property ("can-publish", p_poll, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		p_poll.bind_property ("is-valid", p_attach, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		p_edit.bind_property ("can-publish", p_poll, "can-publish", GLib.BindingFlags.SYNC_CREATE);

		if (editing) p_edit.edit_mode = true;
		p_edit.editor_grab_focus ();
	}

	private void setup_pages (ComposerPage[] pages) {
		foreach (var page in pages) {
			add_page (page);
			page.notify["can-publish"].connect (update_commit_button);
		}

		update_commit_button ();
	}

	private void update_commit_button () {
		var allow = false;
		if (!working) {
			foreach (var page in t_pages) {
				allow = allow || (page.can_publish && page.visible);
				if (allow) break;
			}
		}
		commit_button.sensitive = allow;
	}

	private void update_pages () {
		var allow = false;

		if (!working) {
			allow = true;
		}

		foreach (var page in t_pages) {
			page.sensitive = allow;
		}
	}

	[GtkChild] unowned Adw.ViewSwitcherTitle title_switcher;
	[GtkChild] unowned Button commit_button;

	[GtkChild] unowned Adw.ViewStack stack;

	public Compose (API.Status template = new API.Status.empty ()) {
		Object (
			status: template,
			button_label: _("_Publish"),
			button_class: "suggested-action"
		);
	}

	public Compose.redraft (API.Status status) {
		Object (
			status: status,
			button_label: _("_Redraft"),
			button_class: "destructive-action"
		);
	}

	public Compose.edit (API.Status t_status, API.StatusSource? source = null, owned SuccessCallback? t_cb = null) {
		var template = new API.Status.empty () {
			id = t_status.id,
			poll = t_status.poll,
			sensitive = t_status.sensitive,
			media_attachments = t_status.media_attachments,
			visibility = t_status.visibility,
			language = t_status.language
		};

		if (source == null) {
			template.content = HtmlUtils.remove_tags (t_status.content);
		} else {
			template.content = source.text;
			template.spoiler_text = source.spoiler_text;
		}

		Object (
			status: template,
			button_label: _("_Edit"),
			button_class: "suggested-action",
			editing: true
		);

		this.cb = (owned) t_cb;
	}

	public Compose.reply (API.Status to, owned SuccessCallback? t_cb = null) {
		var template = new API.Status.empty () {
			in_reply_to_id = to.id.to_string (),
			in_reply_to_account_id = to.account.id.to_string (),
			spoiler_text = to.spoiler_text,
			content = to.formal.get_reply_mentions (),
			visibility = to.visibility,
			language = to.language
		};

		Object (
			status: template,
			button_label: _("_Reply"),
			button_class: "suggested-action"
		);

		this.cb = (owned) t_cb;
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
		t_pages += page;
		page.on_build (this, this.status);
		page.on_pull ();

		modify_req.connect (page.on_push);
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
		working = true;
		transaction.begin ((obj, res) => {
			try {
				transaction.end (res);
				// on_close ();
			}
			catch (Error e) {
				working = false;
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
		if (status.id.length > 0) {
			publish_req = new Request () {
				method = "PUT",
				url = @"/api/v1/statuses/$(status.id)",
				account = accounts.active
			};
		}
		modify_req (publish_req);
		yield publish_req.await ();

		var parser = Network.get_parser_from_inputstream(publish_req.response_body);
		var node = network.parse_node (parser);
		var status = API.Status.from (node);
		message (@"Published post with id $(status.id)");
		if (cb != null) cb (status);

		on_close ();
	}

}
