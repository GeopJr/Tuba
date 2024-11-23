[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/compose.ui")]
public class Tuba.Dialogs.Compose : Adw.Dialog {
	public class BasicStatus : Object {
		public class BasicPoll : Object {
			public Gee.ArrayList<string> options { get; set; default=new Gee.ArrayList <string> (); }
			public int64 expires_in { get; set; default=0; }
			public string expires_at { get; set; default=null; }
			public bool multiple { get; set; }
			public bool hide_totals { get; set; default=false; }

			public BasicPoll.from_poll (API.Poll t_poll) {
				if (t_poll.options != null && t_poll.options.size > 0) {
					foreach (API.PollOption p in t_poll.options) {
						options.add (p.title);
					}
				}

				if (t_poll.expires_at != null) {
					var date = new GLib.DateTime.from_iso8601 (t_poll.expires_at, null);
					var now = new GLib.DateTime.now_local ();
					var delta = date.difference (now);

					expires_in = delta / TimeSpan.SECOND;
					expires_at = t_poll.expires_at;
				}

				multiple = t_poll.multiple;
			}

			public bool equal (BasicPoll t_poll) {
				return
					t_poll.multiple == multiple
					&& BasicStatus.array_string_eq (options, t_poll.options);
			}
		}

		public class MediaEntry {
			public string? description = null;
			public string? focus = null;
		}

		public string id { get; set; }
		public string status { get; set; }
		public Gee.ArrayList<string> media_ids { get; private set; default=new Gee.ArrayList<string> (); }
		public Gee.HashMap<string, MediaEntry> media { get; private set; default=new Gee.HashMap<string, MediaEntry> (); }
		public BasicPoll poll { get; set; }
		public string in_reply_to_id { get; set; }
		public bool sensitive { get; set; }
		public string spoiler_text { get; set; }
		public string visibility { get; set; }
		public string language { get; set; }
		public string content_type { get; set; }
		public Gee.ArrayList<API.Attachment>? media_attachments { get; set; default = null; }

		public void add_media (string t_id, string? t_alt, string? t_focus) {
			media_ids.add (t_id);
			media.set (t_id, new MediaEntry () {
				description = t_alt ?? "",
				focus = t_focus ?? ""
			});
		}

		public void clear_media () {
			media_ids.clear ();
			media.clear ();
		}

		public BasicStatus.from_status (API.Status t_status) {
			id = t_status.id;
			status = t_status.content;

			if (t_status.has_media) {
				media_attachments = t_status.media_attachments;

				foreach (var t_attachment in t_status.media_attachments) {
					string focus = "0.00,0.00";

					if (t_attachment.meta != null && t_attachment.meta.focus != null) {
						focus = "%.2f,%.2f".printf (t_attachment.meta.focus.x, t_attachment.meta.focus.y);
					}

					add_media (t_attachment.id, t_attachment.description, focus);
				}
			}

			if (t_status.poll != null) {
				poll = new BasicPoll.from_poll (t_status.poll);
			} else {
				poll = new BasicPoll ();
			}

			in_reply_to_id = t_status.in_reply_to_id;
			sensitive = t_status.sensitive;
			spoiler_text = t_status.spoiler_text;
			visibility = t_status.visibility;
			language = t_status.language;
		}

		public bool equal (BasicStatus t_status) {
			return
				t_status.status == status
				&& t_status.sensitive == sensitive
				&& t_status.spoiler_text == spoiler_text
				&& t_status.visibility == visibility
				&& t_status.language == language
				&& array_string_eq (media_ids, t_status.media_ids)
				&& !media_meta_changed (t_status)
				&& (poll != null && t_status != null ? poll.equal (t_status.poll) : poll == null && t_status == null);
		}

		public static bool array_string_eq (Gee.Collection<string> a1, Gee.Collection<string> a2) {
			if (a1.size != a2.size) return false;
			if (a1.size == 0 && a2.size == 0) return true;
			var res = true;

			foreach (var item in a1) {
				res = a2.contains (item);
				if (!res) break;
			}

			return res;
		}

		public bool media_meta_changed (BasicStatus t_status) {
			var res = false;

			foreach (var entry in this.media.entries) {
				if (!t_status.media.has_key (entry.key)) continue;
				res =
					t_status.media.get (entry.key).description != entry.value.description
					|| t_status.media.get (entry.key).focus != entry.value.focus;
				if (res) break;
			}

			return res;
		}
	}

	public BasicStatus original_status { get; construct set; }
	public BasicStatus status { get; construct set; }
	public bool force_cursor_at_start { get; construct set; default=false; }

	public delegate void SuccessCallback (API.Status cb_status);
	protected SuccessCallback? cb;

	Gtk.Widget commit_button;
	private bool _commit_button_has_menu = false;
	public bool commit_button_has_menu {
		get { return _commit_button_has_menu; }
		construct {
			_commit_button_has_menu = value;

			if (value) {
				var menu_model = new GLib.Menu ();
				// translators: 'Draft' is a verb
				menu_model.append (_("Draft Post"), "composer.draft");

				// translators: 'Schedule' is a verb
				menu_model.append (_("Schedule Post"), "composer.schedule");

				commit_button = new Adw.SplitButton () {
					label = _("_Publish"),
					use_underline = true,
					menu_model = menu_model
				};
				((Adw.SplitButton) commit_button).clicked.connect (on_commit);
			} else {
				commit_button = new Gtk.Button () {
					label = _("_Publish"),
					use_underline = true
				};
				((Gtk.Button) commit_button).clicked.connect (on_commit);
			}

			header.pack_end (commit_button);
		}
	}

	public string button_label {
		set {
			if (_commit_button_has_menu) {
				((Adw.SplitButton) commit_button).label = value;
			} else {
				((Gtk.Button) commit_button).label = value;
			}
		}
	}

	public string button_class {
		set { commit_button.add_css_class (value); }
	}

	public bool editing { get; set; default=false; }

	ulong build_sigid;
	public signal void on_paste_activated (string page_title);
	construct {
		var paste_action = new SimpleAction ("paste", null);
		paste_action.activate.connect (emit_paste_signal);

		var schedule_action = new SimpleAction ("schedule", null);
		schedule_action.activate.connect (on_schedule_action_activated);

		var draft_action = new SimpleAction ("draft", null);
		draft_action.activate.connect (on_draft_action_activated);

		var action_group = new GLib.SimpleActionGroup ();
		action_group.add_action (paste_action);
		action_group.add_action (schedule_action);
		action_group.add_action (draft_action);

		this.insert_action_group ("composer", action_group);
		add_binding_action (Gdk.Key.V, Gdk.ModifierType.CONTROL_MASK, "composer.paste", null);

		title_switcher.policy = WIDE;
		title_switcher.stack = stack;

		build_sigid = notify["status"].connect (() => {
			build ();
			present (app.main_window);

			disconnect (build_sigid);
		});

		stack.notify["visible-child"].connect (on_view_switched);
		this.close_attempt.connect (on_exit);
	}

	~Compose () {
		debug ("Destroying composer");
		t_pages = {};
	}

	void on_view_switched () {
		var child = stack.visible_child as ComposerPage;
		if (child != null) {
			this.title = child.title;
		}
	}

	void emit_paste_signal () {
		on_paste_activated (this.title);
	}

	[GtkCallback] void on_exit () {
		push_all ();

		if (status.equal (original_status)) {
			on_close ();
		} else {
			app.question.begin (
				// translators: Dialog title when closing the composer
				{_("Discard Post?"), false},
				{_("Your progress will be lost."), false},
				this,
				{ { _("Discard"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) on_close ();
				}
			);
		}
	}

	private ComposerPage[] t_pages = {};
	protected virtual signal void build () {
		var p_edit = new EditorPage () {
			force_cursor_at_start = force_cursor_at_start
		};
		var p_attach = new AttachmentsPage ();
		var p_poll = new PollPage ();

		p_edit.ctrl_return_pressed.connect (() => {
			if (commit_button.sensitive) on_commit ();
		});

		setup_pages ({p_edit, p_attach, p_poll});

		// Composer rules
		// 1. Either attachments or polls
		// 2. Poll needs edit to be valid
		p_attach.bind_property (
			"can-publish",
			p_poll,
			"visible",
			GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN
		);
		p_poll.bind_property (
			"is-valid",
			p_attach,
			"visible",
			GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN
		);
		p_edit.bind_property ("can-publish", p_poll, "can-publish", GLib.BindingFlags.SYNC_CREATE);

		this.focus_widget = p_edit.editor;
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
		foreach (var page in t_pages) {
			allow = allow || (page.can_publish && page.visible);
			if (allow) break;
		}
		commit_button.sensitive = allow;
	}

	[GtkChild] unowned Adw.ViewSwitcher title_switcher;
	[GtkChild] unowned Adw.ViewStack stack;
	[GtkChild] unowned Adw.HeaderBar header;

	public string? quote_id { get; set; }
	public Compose (API.Status template = new API.Status.empty (), bool t_force_cursor_at_start = false, string? quote_id = null) {
		Object (
			commit_button_has_menu: true,
			status: new BasicStatus.from_status (template),
			original_status: new BasicStatus.from_status (template),
			button_class: "suggested-action",
			force_cursor_at_start: t_force_cursor_at_start,
			quote_id: quote_id
		);
	}

	public Compose.from_draft (API.Status status, owned SuccessCallback? t_cb = null) {
		Object (
			commit_button_has_menu: true,
			status: new BasicStatus.from_status (status),
			original_status: new BasicStatus.from_status (status),
			button_class: "suggested-action"
		);

		this.cb = (owned) t_cb;
	}


	public Compose.redraft (API.Status status) {
		Object (
			status: new BasicStatus.from_status (status),
			original_status: new BasicStatus.from_status (status),
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
			status: new BasicStatus.from_status (template),
			original_status: new BasicStatus.from_status (template),
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
			status: new BasicStatus.from_status (template),
			original_status: new BasicStatus.from_status (template),
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

	private void push_all () {
		foreach (var page in t_pages) {
			page.on_push ();
		}
	}

	protected void add_page (ComposerPage page) {
		var wrapper = stack.add (page);
		t_pages += page;

		page.dialog = this;
		page.status = this.status;
		if (editing) page.edit_mode = true;
		page.on_build ();
		page.on_pull ();

		modify_body.connect (page.on_push);
		modify_body.connect (page.on_modify_body);
		page.bind_property ("visible", wrapper, "visible", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("title", wrapper, "title", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("icon_name", wrapper, "icon_name", GLib.BindingFlags.SYNC_CREATE);
		page.bind_property ("badge_number", wrapper, "badge_number", GLib.BindingFlags.SYNC_CREATE);
	}

	void on_close () {
		this.force_close ();
		foreach (var page in t_pages) {
			page.unbind_listboxes ();
			stack.remove (page);
		}
	}

	void on_commit () {
		this.sensitive = false;
		transaction.begin ((obj, res) => {
			try {
				transaction.end (res);
			} catch (Error e) {
				warning (e.message);
				var dlg = app.inform (_("Error"), e.message);
				dlg.present (this);
			} finally {
				this.sensitive = true;
			}
		});
	}

	protected signal void modify_body (Json.Builder builder);

	protected virtual void update_metadata (Json.Builder builder) {
		if (
			status.media_ids.size == 0
			|| original_status.media_ids.size == 0
		) return;

		builder.set_member_name ("media_attributes");
		builder.begin_array ();

		foreach (var entry in status.media.entries) {
			if (
				!original_status.media_ids.contains (entry.key)
				|| (
					original_status.media.get (entry.key).description == entry.value.description
					&& original_status.media.get (entry.key).focus == entry.value.focus
				)
			) continue;

			builder.begin_object ();
			builder.set_member_name ("id");
			builder.add_string_value (entry.key);
			builder.set_member_name ("description");
			builder.add_string_value (entry.value.description);
			builder.set_member_name ("focus");
			builder.add_string_value (entry.value.focus);
			builder.end_object ();
		}

		builder.end_array ();
	}

	private string? schedule_iso8601 = null;
	private Json.Builder populate_json_body () {
		var builder = new Json.Builder ();
		builder.begin_object ();

		modify_body (builder);
		if (editing) update_metadata (builder);
		if (quote_id != null) {
			builder.set_member_name ("quote_id");
			builder.add_string_value (quote_id);
		}
		if (schedule_iso8601 != null) {
			builder.set_member_name ("scheduled_at");
			builder.add_string_value (schedule_iso8601);
		}

		builder.end_object ();
		return builder;
	}
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
		publish_req.body_json (populate_json_body ());

		yield publish_req.await ();

		var parser = Network.get_parser_from_inputstream (publish_req.response_body);
		var node = network.parse_node (parser);
		var status = API.Status.from (node);
		debug (@"Published post with id $(status.id)");
		if (cb != null) cb (status);

		on_close ();
	}

	private void on_schedule_action_activated () {
		if (!commit_button.sensitive) return;

		var schedule_dlg = new Dialogs.Schedule ();
		schedule_dlg.schedule_picked.connect (on_schedule_picked);
		schedule_dlg.present (this);
	}

	private void on_draft_action_activated () {
		if (!commit_button.sensitive) return;

		schedule_iso8601 = (new GLib.DateTime.now ()).add_years (3000).format_iso8601 ();
		on_commit ();
	}

	private void on_schedule_picked (string iso8601) {
		schedule_iso8601 = iso8601;
		on_commit ();
	}
}
