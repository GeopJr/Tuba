public class Tuba.Views.Thread : Views.ContentBase, AccountHolder {
	public enum ThreadRole {
		NONE,
		START,
		MIDDLE,
		END;

		public static void connect_posts (API.Status? prev, API.Status curr) {
			if (prev == null) return;

			switch (prev.tuba_thread_role) {
				case NONE:
					prev.tuba_thread_role = START;
					curr.tuba_thread_role = END;
					break;
				default:
					prev.tuba_thread_role = MIDDLE;
					curr.tuba_thread_role = END;
					break;
			}
		}
	}

	protected InstanceAccount? account { get; set; }
	public API.Status root_status { get; set; }

	public Thread (API.Status status) {
		Object (
			root_status: status,
			base_status: new StatusMessage () { loading = true },
			label: _("Conversation"),
			allow_nesting: true
		);
		construct_account_holder ();
	}
	~Thread () {
		critical ("Destroying Thread");
		destruct_account_holder ();
	}

	public override void on_account_changed (InstanceAccount? acc) {
		account = acc;
		GLib.Idle.add (request);
	}

	void connect_threads () {
		API.Status? last_status = null;
		string? last_id = null;
		for (var pos = 0; pos < model.n_items; pos++) {
			var status = model.get_item (pos) as API.Status;
			status.tuba_thread_role = ThreadRole.NONE;

			var id = status.formal.in_reply_to_id;

			if (id == last_id) {
				ThreadRole.connect_posts (last_status, status);
			}

			last_id = status.formal.id;
			last_status = status;
		}
	}

	private void on_replied (API.Status t_status) {
		var found = false;
		if (t_status.in_reply_to_id != null) {
			for (uint i = 0; i < model.get_n_items (); i++) {
				var status_obj = (API.Status)model.get_item (i);
				if (status_obj.id == t_status.in_reply_to_id) {
					model.insert (i + 1, t_status);
					found = true;
					break;
				}
			}
		}

		if (!found) model.append (t_status);
		connect_threads ();
	}

	private bool _reveal_spoilers = settings.show_spoilers;
	private bool reveal_spoilers {
		get {
			return _reveal_spoilers;
		}

		set {
			for (var pos = 0; pos < model.n_items; pos++) {
				var status = model.get_item (pos) as API.Status;

				if (status.has_spoiler)
					status.tuba_spoiler_revealed = value;
			}
			_reveal_spoilers = value;
		}
	}

	private Gtk.ToggleButton spoiler_toggle_button;
	protected override void build_header () {
		base.build_header ();

		spoiler_toggle_button = new Gtk.ToggleButton () {
			icon_name = "tuba-eye-open-negative-filled-symbolic",
			tooltip_text = _("Reveal Spoilers"),
			active = _reveal_spoilers,
			visible = false
		};
		spoiler_toggle_button.toggled.connect (spoiler_toggle_button_toggled);

		header.pack_end (spoiler_toggle_button);
	}

	private void spoiler_toggle_button_toggled () {
		var spoiler_toggle_button_active = spoiler_toggle_button.active;
		spoiler_toggle_button.icon_name = spoiler_toggle_button_active
			? "tuba-eye-not-looking-symbolic"
			: "tuba-eye-open-negative-filled-symbolic";
		spoiler_toggle_button.tooltip_text = spoiler_toggle_button_active ? _("Hide Spoilers") : _("Reveal Spoilers");
		reveal_spoilers = spoiler_toggle_button_active;
	}

	public override void on_content_changed () {
		for (uint i = 0; i < model.n_items; i++) {
			var status = (API.Status) model.get_item (i);
			if (status.has_spoiler) {
				spoiler_toggle_button.visible = true;
				break;
			}
		}
		base.on_content_changed ();
	}

	public bool request () {
		new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
			.with_account (account)
			.with_ctx (this)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var root = network.parse (parser);

				Object[] to_add_ancestors = {};
				var ancestors = root.get_array_member ("ancestors");
				ancestors.foreach_element ((array, i, node) => {
					var e = Tuba.Helper.Entity.from_json (node, typeof (API.Status));
					to_add_ancestors += e;
				});
				to_add_ancestors += root_status;
				model.splice (model.get_n_items (), 0, to_add_ancestors);

				Object[] to_add_descendants = {};
				var descendants = root.get_array_member ("descendants");
				descendants.foreach_element ((array, i, node) => {
					var e = Tuba.Helper.Entity.from_json (node, typeof (API.Status));
					to_add_descendants += e;
				});
				model.splice (model.get_n_items (), 0, to_add_descendants);

				connect_threads ();
				on_content_changed ();

				#if GTK_4_12 && USE_LISTVIEW
					if (to_add_ancestors.length > 0) {
						uint timeout = 0;
						timeout = Timeout.add (1000, () => {
							content.scroll_to (to_add_ancestors.length, Gtk.ListScrollFlags.FOCUS, null);

							GLib.Source.remove (timeout);
							return true;
						}, Priority.LOW);
					}
				#endif
			})
			.exec ();

		return GLib.Source.REMOVE;
	}

	public static void open_from_link (string q) {
		new Request.GET ("/api/v1/search")
			.with_account ()
			.with_param ("q", q)
			.with_param ("resolve", "true")
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var root = network.parse (parser);
				var statuses = root.get_array_member ("statuses");
				var node = statuses.get_element (0);
				if (node != null) {
					var status = API.Status.from (node);
					app.main_window.open_view (new Views.Thread (status));
				}
				else
					Host.open_uri (q);
			})
			.exec ();
	}

	public override Gtk.Widget on_create_model_widget (Object obj) {
		var widget = base.on_create_model_widget (obj);
		var widget_status = widget as Widgets.Status;

		widget_status.reply_cb = on_replied;
		widget_status.enable_thread_lines = true;
		widget_status.content.selectable = true;

		if (((API.Status) obj).id == root_status.id) {
			#if !USE_LISTVIEW
				widget_status.activatable = false;
			#endif
			widget_status.expand_root ();
		}

		return widget_status;
	}

	#if USE_LISTVIEW
	protected override void bind_listitem_cb (GLib.Object item) {
			base.bind_listitem_cb (item);

			if (((API.Status) ((Gtk.ListItem) item).item).id == root_status.id)
				((Gtk.ListItem) item).activatable = false;
		}
	#endif
}
