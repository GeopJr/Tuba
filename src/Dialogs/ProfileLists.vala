public class Tuba.Dialogs.ProfileLists : Adw.Dialog {
	public signal void errored (int32 code, string message);

	public class ARRow : Adw.ActionRow {
		public signal void errored (GLib.Error error);
		public signal void toast (Adw.Toast toast);

		public bool is_already_in_list { get; set; default = false; }
		private API.List list { get; set; }
		Gtk.Button add_button;
		string profile_id;
		string profile_handle;

		public ARRow (API.List list, bool is_in_list, string profile_id, string profile_handle) {
			this.list = list;
			this.is_already_in_list = is_in_list;
			this.use_markup = false;
			this.title = list.title;
			this.profile_id = profile_id;
			this.profile_handle = profile_handle;

			add_button = new Gtk.Button () {
				halign = Gtk.Align.CENTER,
				valign = Gtk.Align.CENTER,
				css_classes = { "flat", "circular" }
			};
			add_button.clicked.connect (on_clicked);
			update_button_state ();

			this.add_suffix (add_button);
		}

		private void on_clicked () {
			handle_list_edit.begin ();
		}

		private void update_button_state () {
			if (!this.is_already_in_list) {
				add_button.icon_name = "tuba-plus-large-symbolic";
				//  translators: First variable is a handle, second variable is a list name;
				//				 tooltip on a button that adds the user in question to the list
				add_button.tooltip_text = _("Add \"%s\" to \"%s\"").printf (profile_handle, list.title);
			} else {
				add_button.icon_name = "tuba-minus-large-symbolic";
				//  translators: First variable is a handle, second variable is a list name;
				//				 tooltip on a button that removes the user in question from the list
				add_button.tooltip_text = _("Remove \"%s\" from \"%s\"").printf (profile_handle, list.title);
			}
		}

		private async void handle_list_edit () {
			this.sensitive = false;

			var builder = new Json.Builder ();
			builder.begin_object ();
			builder.set_member_name ("account_ids");
			builder.begin_array ();
			builder.add_string_value (profile_id);
			builder.end_array ();
			builder.end_object ();

			var endpoint = @"/api/v1/lists/$(list.id)/accounts";
			var req = new RequestV2 (endpoint, this.is_already_in_list ? RequestV2.Method.DELETE : RequestV2.Method.POST) { account = accounts.active, ctx = this };
			req.set_body_from_json (builder);
			try {
				yield req.exec (null);
				var toast_msg = "";
				if (this.is_already_in_list) {
					//  translators: First variable is a handle, second variable is a list name;
					//				 toast that shows up when successfully removing the user in
					//				 question from the list
					toast_msg = _("User \"%s\" got removed from \"%s\"").printf (profile_handle, list.title);
				} else {
					//  translators: First variable is a handle, second variable is a list name;
					//				 toast that shows up when successfully adding the user in
					//				 question from the list
					toast_msg = _("User \"%s\" got added to \"%s\"").printf (profile_handle, list.title);
				}

				this.is_already_in_list = !this.is_already_in_list;
				update_button_state ();
				this.sensitive = true;

				var toasted = new Adw.Toast (toast_msg);
				toast (toasted);
			} catch (Error e) {
				errored (e);
			}
		}
	}

	Adw.PreferencesPage preferences_page;
	Adw.PreferencesGroup preferences_group;
	Adw.ToastOverlay toast_overlay;
	Adw.StatusPage no_lists_page;
	string profile_id;
	string profile_handle;
	public ProfileLists (string profile_id, string profile_handle) {
		// translators: the variable is an account handle; title on a
		//				dialog that allows the user to remove or add
		//				another user from or to their lists
		this.title = _("Add or remove \"%s\" to or from a list").printf (profile_handle);
		this.content_width = 600;
		this.content_height = 550;
		this.profile_id = profile_id;
		this.profile_handle = profile_handle;

		var spinner = new Adw.Spinner () {
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			vexpand = true,
			hexpand = true,
			width_request = 32,
			height_request = 32
		};
		var toolbar_view = new Adw.ToolbarView ();
		var headerbar = new Adw.HeaderBar ();
		toast_overlay = new Adw.ToastOverlay () {
			vexpand = true,
			valign = Gtk.Align.CENTER
		};
		toast_overlay.child = spinner;

		toolbar_view.add_top_bar (headerbar);
		toolbar_view.set_content (toast_overlay);

		preferences_page = new Adw.PreferencesPage ();
		preferences_group = new Adw.PreferencesGroup () {
			title = _("Lists"),
			// translators: the variable is an account handle; subtitle shown on a
			//				dialog that allows the user to remove or add another
			//				user from or to their lists
			description = _("Select the list to add or remove \"%s\" to or from:").printf (profile_handle)
		};

		no_lists_page = new Adw.StatusPage () {
			icon_name = "dialog-error-symbolic",
			vexpand = true,
			// translators: message shown on a dialog that allows the user to remove or add another
			//				user from or to their lists, when they don't have any lists
			title = _("You don't have any lists")
		};

		fill_ar_list.begin ();
		this.child = toolbar_view;
	}

	private async void fill_ar_list () {
		var req = new RequestV2 ("/api/v1/lists/") { account = accounts.active, ctx = this };
		try {
			var in_stream = yield req.exec (null);
			Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
			if (Network.get_array_size (parser) > 0) {
				var list_req = new RequestV2 (@"/api/v1/accounts/$(profile_id)/lists") { account = accounts.active, ctx = this };
				try {
					var list_in_stream = yield list_req.exec (null);
					Json.Parser list_parser = yield Network.get_parser_from_inputstream_async (list_in_stream);

					var added = false;
					var in_list = new Gee.ArrayList<string> ();

					Network.parse_array (list_parser, node => {
						var list = API.List.from (node);
						in_list.add (list.id);
					});
					Network.parse_array (parser, node => {
						var list = API.List.from (node);
						var row = new ARRow (list, in_list.contains (list.id), profile_id, profile_handle);
						row.toast.connect (on_row_toast);
						row.errored.connect (on_row_errored);
						preferences_group.add (row);
						added = true;
					});

					if (added) {
						preferences_page.add (preferences_group);

						toast_overlay.child = preferences_page;
						toast_overlay.valign = Gtk.Align.FILL;
					} else {
						toast_overlay.child = no_lists_page;
					}
				} catch (Error e) {
					errored (e.code, e.message);
				}
			} else {
				toast_overlay.child = no_lists_page;
			}
		} catch (Error e) {
			errored (e.code, e.message);
		}
	}

	private void on_row_toast (Adw.Toast toast) {
		toast_overlay.add_toast (toast);
	}

	private void on_row_errored (GLib.Error e) {
		errored (e.code, e.message);
	}
}
