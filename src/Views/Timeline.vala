using Gtk;
using Gdk;

public class Tooth.Views.Timeline : AccountHolder, Streamable, Views.ContentBase {

	public string url { get; construct set; }
	public bool is_public { get; construct set; default = false; }
	public Type accepts { get; set; default = typeof (API.Status); }

	protected InstanceAccount? account { get; set; default = null; }

	public bool is_last_page { get; set; default = false; }
	public string? page_next { get; set; }
	public string? page_prev { get; set; }

	construct {
		app.refresh.connect (on_refresh);
		status_button.clicked.connect (on_refresh);

		construct_account_holder ();

		construct_streamable ();
		stream_event[InstanceAccount.EVENT_NEW_POST].connect (on_new_post);
		stream_event[InstanceAccount.EVENT_DELETE_POST].connect (on_delete_post);

		content.bind_model (model, on_create_model_widget);
	}
	~Timeline () {
		destruct_account_holder ();
		destruct_streamable ();

		content.bind_model (null, null);
	}

	public virtual bool is_status_owned (API.Status status) {
		return status.is_owned ();
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
		if (header == null)
			return;

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

	public virtual void on_request_finish () {}

	public virtual bool request () {
		var req = append_params (new Request.GET (get_req_url ()))
		.with_account (account)
		.with_ctx (this)
		.then ((sess, msg) => {
			Network.parse_array (msg, node => {
				try {
					var e = entity_cache.lookup_or_insert (node, accepts);
					model.append (e); //FIXME: use splice();
				}
				catch (Error e) {
					warning (@"Timeline item parse error: $(e.message)");
				}
			});

			get_pages (msg.response_headers.get_one ("Link"));
			on_content_changed ();
			on_request_finish ();
		})
		.on_error (on_error);
		req.exec ();

		return GLib.Source.REMOVE;
	}

	public virtual void on_refresh () {
		scrolled.vadjustment.value = 0;
		status_button.sensitive = false;
		clear ();
		status_message = STATUS_LOADING;
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
		var entity = Entity.from_json (accepts, ev.get_node ());
		model.insert (0, entity);
	}

	public virtual void on_delete_post (Streamable.Event ev) {
		//TODO: This
	}

}
