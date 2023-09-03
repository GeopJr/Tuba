public class Tuba.Views.Thread : Views.ContentBase, AccountHolder {
	public enum ThreadRole {
		NONE,
		START,
		MIDDLE,
		END;

		public static void connect_posts (API.Status? prev, API.Status curr) {
			if (prev == null) {
				curr.tuba_thread_role = NONE;
				return;
			}

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
		debug ("Destroying Thread");
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

	public bool request () {
		new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
			.with_account (account)
			.with_ctx (this)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var root = network.parse (parser);

				Object[] to_add_ancestors = {};
				var ancestors = root.get_array_member ("ancestors");
				ancestors.foreach_element ((array, i, node) => {
					var e = entity_cache.lookup_or_insert (node, typeof (API.Status));
					to_add_ancestors += e;
				});
				to_add_ancestors += root_status;
				model.splice (model.get_n_items (), 0, to_add_ancestors);

				Object[] to_add_descendants = {};
				var descendants = root.get_array_member ("descendants");
				descendants.foreach_element ((array, i, node) => {
					var e = entity_cache.lookup_or_insert (node, typeof (API.Status));
					to_add_descendants += e;
				});
				model.splice (model.get_n_items (), 0, to_add_descendants);

				connect_threads ();
				on_content_changed ();

				#if GTK_4_12
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
			.then ((sess, msg, in_stream) => {
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

		if (((API.Status) obj).id == root_status.id) widget_status.expand_root ();

		return widget_status;
	}

}
