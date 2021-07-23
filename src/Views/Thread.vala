using Gtk;

public class Tootle.Views.Thread : Views.ContentBase, AccountHolder {

	protected InstanceAccount? account { get; set; }
	public API.Status root_status { get; set; }
	protected unowned Widgets.Status root_widget;

	public Thread (API.Status status) {
		Object (
			root_status: status,
			status_message: STATUS_LOADING,
			label: _("Conversation")
		);
		construct_account_holder ();
	}
	~Thread () {
		message ("Destroying Thread");
		destruct_account_holder ();
	}

	public override void on_account_changed (InstanceAccount? acc) {
		account = acc;
		request ();
	}

	void connect_threads () {
		Widgets.Status? last_w = null;
		string? last_id = null;

		for (var w = content.get_row_at_index (0) as Widgets.Status;
				w != null;
				w = w.get_next_sibling () as Widgets.Status) {

			var id = w.status.formal.in_reply_to_id;

			if (id == last_id) {
				Widgets.Status.ThreadRole.connect_posts (last_w, w);
			}

			last_w = w;
			last_id = w.status.formal.id;
		}

		for (var w = content.get_row_at_index (0) as Widgets.Status;
				w != null;
				w = w.get_next_sibling () as Widgets.Status) {

			w.install_thread_line ();
		}

		root_widget.thread_line.hide ();
	}

	public void request () {
		new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
			.with_account (account)
			.with_ctx (this)
			.then ((sess, msg) => {
				var root = network.parse (msg);

				var ancestors = root.get_array_member ("ancestors");
				ancestors.foreach_element ((array, i, node) => {
					var e = entity_cache.lookup_or_insert (node, typeof (API.Status));
					model.append (e);
				});

				model.append (root_status);
				uint root_index;
				model.find (root_status, out root_index);
				root_widget = content.get_row_at_index ((int)root_index) as Widgets.Status;
				root_widget.expand_root ();

				var descendants = root.get_array_member ("descendants");
				descendants.foreach_element ((array, i, node) => {
					var e = entity_cache.lookup_or_insert (node, typeof (API.Status));
					model.append (e);
				});

				connect_threads ();
				on_content_changed ();

				//FIXME: scroll to expanded post
				// int x,y;
				// translate_coordinates (root_widget, 0, header.get_allocated_height (), out x, out y);
				// scrolled.vadjustment.value = (double)(y*-1);
			})
			.exec ();
	}

	public static void open_from_link (string q) {
		new Request.GET ("/api/v1/search")
			.with_account ()
			.with_param ("q", q)
			.with_param ("resolve", "true")
			.then ((sess, msg) => {
				var root = network.parse (msg);
				var statuses = root.get_array_member ("statuses");
				var node = statuses.get_element (0);
				if (node != null){
					var status = API.Status.from (node);
					app.main_window.open_view (new Views.Thread (status));
				}
				else
					Host.open_uri (q);
			})
			.exec ();
	}

}
