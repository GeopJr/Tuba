using Gtk;

[GtkTemplate (ui = "/dev/geopjr/tooth/ui/dialogs/list_editor.ui")]
public class Tooth.Dialogs.ListEditor: Adw.Window {

	[GtkTemplate (ui = "/dev/geopjr/tooth/ui/widgets/list_editor_item.ui")]
	class Item : ListBoxRow {

		public ListEditor editor { get; construct set; }
		public API.Account acc { get; construct set; }
		public bool committed { get; construct set; }

		[GtkChild] unowned Widgets.RichLabel label;
		[GtkChild] unowned Widgets.RichLabel handle;
		[GtkChild] unowned ToggleButton status;

		public Item (ListEditor editor, API.Account acc, bool committed) {
			this.editor = editor;
			this.acc = acc;
			this.committed = committed;
			acc.bind_property ("display-name", label, "text", BindingFlags.SYNC_CREATE);
			acc.bind_property ("handle", handle, "text", BindingFlags.SYNC_CREATE);
			status.active = committed;
			status.sensitive = true;
		}

		[GtkCallback]
		void on_toggled () {
			if (!status.sensitive)
				return;

			if (status.active) {
				debug (@"To add: $(acc.id)");
				editor.to_add.add (acc.id);
				editor.to_remove.remove (acc.id);
			}
			else {
				debug (@"To remove: $(acc.id)");
				editor.to_add.remove (acc.id);
				editor.to_remove.add (acc.id);
			}
			committed = status.active;
			if (!editor.working)
				editor.dirty = true;
		}

	}

	public API.List list { get; set; }
	public bool working { get; set; default = false; }
	public bool exists { get; set; default = false; }
	public bool dirty { get; set; default = false; }

	Soup.Message? search_req = null;

	public Gee.ArrayList<string> to_add = new Gee.ArrayList<string> ();
	public Gee.ArrayList<string> to_remove = new Gee.ArrayList<string> ();

	[GtkChild] unowned Button save_btn;
	[GtkChild] unowned Stack save_btn_stack;
	[GtkChild] unowned Entry name_entry;
	[GtkChild] unowned SearchEntry search_entry;
	[GtkChild] unowned ListBox listbox;

	[GtkChild] unowned InfoBar infobar;
	[GtkChild] unowned Label infobar_label;

	public signal void done ();

	construct {
		transient_for = app.main_window;
		show ();
	}

	public ListEditor.empty () {
		var obj = new API.List () {
			title = _("Untitled")
		};
		Object (list: obj);
		init ();
	}

	public ListEditor (API.List list) {
		Object (list: list, working: true, exists: true);
		init ();

		new Request.GET (@"/api/v1/lists/$(list.id)/accounts")
			.with_account (accounts.active)
			.with_ctx (this)
			.on_error (on_error)
			.then ((sess, msg) => {
				Network.parse_array (msg, node => {
					var acc = API.Account.from (node);
					add_account (acc, true);
				});
				working = false;
			})
			.exec ();
	}

	void init () {
		notify["working"].connect (on_state_changed);
		list.bind_property ("title", name_entry, "text", BindingFlags.SYNC_CREATE);

		ulong dirty_sigid = 0;
		dirty_sigid = name_entry.changed.connect (() => {
			dirty = true;
			name_entry.disconnect (dirty_sigid);
		});

		on_state_changed (null);
	}

	void on_state_changed (ParamSpec? p) {
		save_btn_stack.visible_child_name = working ? "working" : "done";
		save_btn.sensitive = search_entry.sensitive = name_entry.sensitive = !working;
	}

	void on_error (int32 code, string msg) {
		warning (msg);
		infobar_label.label = msg;
		infobar.revealed = true;
	}

	[GtkCallback]
	void infobar_response (int i) {
		infobar.revealed = false;
	}

	void request_search (string q) {
		debug (@"Searching for: \"$q\"...");
		if (search_req != null) {
			network.cancel (search_req);
			search_req = null;
		}

		search_req = new Request.GET ("/api/v1/accounts/search")
			.with_account (accounts.active)
			.with_ctx (this)
			.with_param ("resolve", "false")
			.with_param ("limit", "8")
			.with_param ("following", "true")
			.with_param ("q", q)
			.then ((sess, msg) => {
				Network.parse_array (msg, node => {
					var acc = API.Account.from (node);
					add_account (acc, false, 0);
				});
			})
			.on_error (on_error)
			.exec ();
	}

	void add_account (API.Account acc, bool added, int order = -1) {
		var exists = false;
		// listbox.@foreach (w => {
		// 	var i = w as Item;
		// 	if (i != null) {
		// 		if (i.acc.id == acc.id)
		// 			exists = true;
		// 	}
		// });

		if (!exists) {
			var item = new Item (this, acc, added);
			listbox.insert (item, order);
		}
	}

	void invalidate () {
		// listbox.@foreach (w => {
		// 	var i = w as Item;
		// 	if (i != null) {
		// 		if (!i.committed)
		// 			i.destroy ();
		// 	}
		// });
	}


	[GtkCallback]
	void validate () {
		var has_title = name_entry.text.replace (" ", "") != "";
		save_btn.sensitive = has_title;
	}

	[GtkCallback]
	void on_cancel_clicked () {
		if (dirty) {
			var dlg = app.question (
				_("Discard changes?"),
				_("You need to save the list if you want to keep them."),
				this,
				_("Discard"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			dlg.response.connect(res => {
				if (res == "yes") {
					destroy ();
				}
				dlg.destroy();
			});

			dlg.present ();
		}
		else
			destroy ();
	}

	[GtkCallback]
	void on_search_changed () {
		var q = search_entry.text.chug ().chomp ();

		if (q.char_count () < 3)
			invalidate ();
		else if (q != "") {
			invalidate ();
			request_search (q);
		}
	}

	[GtkCallback]
	void on_save_clicked () {
		working = true;
		transaction.begin ((obj, res) => {
			try {
				transaction.end (res);

				done ();
				destroy ();
			}
			catch (Error e) {
				working = false;
				on_error (0, e.message);
			}
		});
	}

	async void transaction () throws Error {
		if (!exists) {
			message ("Creating list...");
			var req = new Request.POST ("/api/v1/lists")
				.with_account (accounts.active)
				.with_param ("title", name_entry.text);
			yield req.await ();

			message ("Received new List entity");
			var node = network.parse_node (req);
			list = API.List.from (node);
		}
		else {
			message ("Updating list title...");
			yield new Request.PUT (@"/api/v1/lists/$(list.id)")
				.with_account (accounts.active)
				.with_param ("title", name_entry.text)
				.await ();
		}

		if (!to_add.is_empty) {
			message ("Adding accounts to list...");
			var id_array = Request.array2string (to_add, "account_ids");
		 	yield new Request.POST (@"/api/v1/lists/$(list.id)/accounts/?$id_array")
		 		.with_account (accounts.active)
		 		.await ();
		}

		if (!to_remove.is_empty) {
			message ("Removing accounts from list...");
			var id_array = Request.array2string (to_remove, "account_ids");
		 	yield new Request.DELETE (@"/api/v1/lists/$(list.id)/accounts/?$id_array")
		 		.with_account (accounts.active)
		 		.await ();
		}

		message ("OK: List updated");
		list.title = name_entry.text;
	}

}
