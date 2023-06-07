using Gtk;
using Gdk;

public class Tuba.Views.Timeline : AccountHolder, Streamable, Views.ContentBase {

	public string url { get; construct set; }
	public bool is_public { get; construct set; default = false; }
	public Type accepts { get; set; default = typeof (API.Status); }
	public bool use_queue { get; set; default = true; }

	protected InstanceAccount? account { get; set; default = null; }

	public bool is_last_page { get; set; default = false; }
	public string? page_next { get; set; }
	public string? page_prev { get; set; }
	Entity[] entity_queue = {};

	construct {
		reached_close_to_top.connect (finish_queue);
		app.refresh.connect (on_refresh);
		status_button.clicked.connect (on_refresh);

		construct_account_holder ();

		construct_streamable ();
		stream_event[InstanceAccount.EVENT_NEW_POST].connect (on_new_post);
		stream_event[InstanceAccount.EVENT_EDIT_POST].connect (on_edit_post);
		stream_event[InstanceAccount.EVENT_DELETE_POST].connect (on_delete_post);
		settings.notify["show-spoilers"].connect (on_refresh);
		settings.notify["hide-preview-cards"].connect (on_refresh);
		settings.notify["only-op-home"].connect (on_refresh);

		content.bind_model (model, on_create_model_widget);
	}
	~Timeline () {
		message (@"Destroying Timeline $label");

		entity_queue = {};
		destruct_account_holder ();
		destruct_streamable ();

		content.bind_model (null, null);
	}

	public override void dispose () {
		destruct_streamable ();
		base.dispose ();
	}

	public virtual bool is_status_owned (API.Status status) {
		return status.is_owned ();
	}

	public virtual bool filter (Entity entity) {
		return true;
	}

	public override void clear () {
		this.page_prev = null;
		this.page_next = null;
		this.is_last_page = false;
		this.needs_attention = false;
		this.badge_number = 0;
		base.clear ();
	}

	public void get_pages (string? header) {
		page_next = page_prev = null;
		if (header == null) {
			is_last_page = true;
			return;
		};

		var pages = header.split (",");
		foreach (var page in pages) {
			var sanitized = page
				.replace ("<","")
				.replace (">", "")
				.split (";")[0];

			if ("rel=\"prev\"" in page)
				page_prev = sanitized;
			else
				page_next = sanitized;
		}

		is_last_page = page_prev != null & page_next == null;
	}

	public virtual string get_req_url () {
		if (page_next != null)
			return page_next;
		return url;
	}

	public virtual Request append_params (Request req) {
		if (page_next == null)
			return req.with_param ("limit", @"$(settings.timeline_page_size)");
		else
			return req;
	}

	public virtual void on_request_finish () {
		base.on_bottom_reached ();
	}

	public virtual bool request () {
		append_params (new Request.GET (get_req_url ()))
			.with_account (account)
			.with_ctx (this)
			.then ((sess, msg, in_stream) => {
				var parser = Network.get_parser_from_inputstream(in_stream);

				Object[] to_add = {};
				Network.parse_array (msg, parser, node => {
					var e = entity_cache.lookup_or_insert (node, accepts);

					if (filter (e))
						to_add += e;
				});

				get_pages (msg.response_headers.get_one ("Link"));

				if (to_add.length == 0 && !is_last_page) {
					request ();
				} else {
					model.splice (model.get_n_items (), 0, to_add);
					on_content_changed ();
					on_request_finish ();

					if (model.get_n_items() < settings.timeline_page_size && !is_last_page) request ();
				}
			})
			.on_error (on_error)
			.exec ();

		return GLib.Source.REMOVE;
	}

	public virtual void on_refresh () {
		entity_queue = {};
		scrolled.vadjustment.value = 0;
		status_button.sensitive = false;
		clear ();
		base_status = new StatusMessage () { loading = true };
		GLib.Idle.add (request);
	}


	protected virtual void on_account_changed (InstanceAccount? acc) {
		account = acc;
		update_stream ();
		on_refresh ();
	}

	protected override void on_bottom_reached () {
		if (is_last_page) {
			info ("Last page reached");
			return;
		}
		request ();
	}



	// Streamable

	public string? t_connection_url { get; set; }
	public bool subscribed { get; set; }

	protected override void on_streaming_policy_changed () {
		var allow_streaming = settings.live_updates;
		if (is_public)
			allow_streaming = allow_streaming && settings.public_live_updates;

		subscribed = allow_streaming;
	}

	public virtual string? get_stream_url () {
		return null;
	}

	public virtual void on_new_post (Streamable.Event ev) {
		try {
			var entity = Entity.from_json (accepts, ev.get_node ());

			if (!filter (entity)) return;

			if (use_queue && scrolled.vadjustment.value > 1000) {
				entity_queue += entity;
				return;
			}

			model.insert (0, entity);
		} catch (Error e) {
			warning (@"Error getting Entity from json: $(e.message)");
		}
	}

	private void finish_queue () {
		if (entity_queue.length == 0) return;
		model.splice (0, 0, (Object[])entity_queue);

		entity_queue = {};
	}

	public virtual void on_edit_post (Streamable.Event ev) {
		try {
			var entity = Entity.from_json (accepts, ev.get_node ());
			var entity_id = ((API.Status)entity).id;
			for (uint i = 0; i < model.get_n_items(); i++) {
				var status_obj = (API.Status)model.get_item(i);
				if (status_obj.id == entity_id) {
					model.remove(i);
					model.insert (i, entity);
					break;
				}
			}
		} catch (Error e) {
			warning (@"Error getting Entity from json: $(e.message)");
		}
	}

	public virtual void on_delete_post (Streamable.Event ev) {
		try {
			var status_id = ev.get_string ();

			for (uint i = 0; i < model.get_n_items(); i++) {
				var status_obj = (API.Status)model.get_item(i);
				// Not sure if there can be both the original
				// and a boost of it at the same time.
				if (status_obj.id == status_id || status_obj.formal.id == status_id) {
					model.remove(i);
					// If there can be both the original
					// and boosts at the same time, then
					// it shouldn't stop at the first find.
					break;
				}
			}
		} catch (Error e) {
			warning (@"Error getting String from json: $(e.message)");
		}
	}
}
