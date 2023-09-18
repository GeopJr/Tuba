public class Tuba.Views.Timeline : AccountHolder, Streamable, Views.ContentBase {

	public string url { get; construct set; }
	public bool is_public { get; construct set; default = false; }
	public Type accepts { get; set; default = typeof (API.Status); }

	protected InstanceAccount? account { get; set; default = null; }

	public bool is_last_page { get; set; default = false; }
	public string? page_next { get; set; }
	public string? page_prev { get; set; }

	private Gtk.Spinner pull_to_refresh_spinner;
	private bool _is_pulling = false;
	private bool is_pulling {
		get {
			return _is_pulling;
		}
		set {
			if (_is_pulling != value) {
				if (value) {
					pull_to_refresh_spinner.spinning = true;
					scrolled_overlay.add_overlay (pull_to_refresh_spinner);
					scrolled.sensitive = false;
				} else {
					pull_to_refresh_spinner.spinning = false;
					scrolled_overlay.remove_overlay (pull_to_refresh_spinner);
					scrolled.sensitive = true;
					pull_to_refresh_spinner.margin_top = 32;
					pull_to_refresh_spinner.height_request = 32;
				}
				_is_pulling = value;
			}
		}
	}

    private void on_drag_update (double x, double y) {
		if (scrolled.vadjustment.value != 0.0 || (y <= 0 && !is_pulling)) return;
		is_pulling = true;

		double clean_y = y;
		if (y > 150) {
			clean_y = 150;
		} else if (y < -32) {
			clean_y = -32;
		}

		if (clean_y > 32) {
			pull_to_refresh_spinner.margin_top = (int) clean_y;
			pull_to_refresh_spinner.height_request = pull_to_refresh_spinner.width_request = 32;
		} else if (clean_y > 0) {
			pull_to_refresh_spinner.height_request = pull_to_refresh_spinner.width_request = (int) clean_y;
		} else {
			pull_to_refresh_spinner.margin_top = 32;
			pull_to_refresh_spinner.height_request = pull_to_refresh_spinner.width_request = 0;
		}
    }

	private void on_drag_end (double x, double y) {
        if (scrolled.vadjustment.value == 0.0 && pull_to_refresh_spinner.margin_top >= 125) {
            on_refresh ();
        }

		is_pulling = false;
    }

	construct {
		pull_to_refresh_spinner = new Gtk.Spinner () {
			height_request = 32,
			width_request = 32,
			margin_top = 32,
			margin_bottom = 32,
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.START,
			css_classes = { "osd", "circular-spinner" }
		};

		app.refresh.connect (on_refresh);
		status_button.clicked.connect (on_refresh);

		construct_account_holder ();

		construct_streamable ();
		stream_event[InstanceAccount.EVENT_NEW_POST].connect (on_new_post);

		if (accepts == typeof (API.Status)) {
			stream_event[InstanceAccount.EVENT_EDIT_POST].connect (on_edit_post);
			stream_event[InstanceAccount.EVENT_DELETE_POST].connect (on_delete_post);
		}

		settings.notify["show-spoilers"].connect (on_refresh);
		settings.notify["hide-preview-cards"].connect (on_refresh);
		settings.notify["enlarge-custom-emojis"].connect (on_refresh);

		var drag = new Gtk.GestureDrag ();
        drag.drag_update.connect (on_drag_update);
        drag.drag_end.connect (on_drag_end);
        this.add_controller (drag);
	}
	~Timeline () {
		debug (@"Destroying Timeline $label");

		destruct_account_holder ();
		destruct_streamable ();
	}

	public override void dispose () {
		destruct_streamable ();
		base.dispose ();
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
				.replace ("<", "")
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
			return req.with_param ("limit", settings.timeline_page_size.to_string ());
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
				var parser = Network.get_parser_from_inputstream (in_stream);

				Object[] to_add = {};
				Network.parse_array (msg, parser, node => {
					var e = entity_cache.lookup_or_insert (node, accepts);
					to_add += e;
				});
				model.splice (model.get_n_items (), 0, to_add);

				get_pages (msg.response_headers.get_one ("Link"));
				on_content_changed ();
				on_request_finish ();
			})
			.on_error (on_error)
			.exec ();

		return GLib.Source.REMOVE;
	}

	public virtual void on_refresh () {
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
			model.insert (0, Entity.from_json (accepts, ev.get_node ()));
		} catch (Error e) {
			warning (@"Error getting Entity from json: $(e.message)");
		}
	}

	public virtual void on_edit_post (Streamable.Event ev) {
		try {
			var entity = Entity.from_json (accepts, ev.get_node ());
			var entity_id = ((API.Status)entity).id;
			for (uint i = 0; i < model.get_n_items (); i++) {
				var status_obj = (API.Status)model.get_item (i);
				if (status_obj.id == entity_id) {
					model.remove (i);
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

			for (uint i = 0; i < model.get_n_items (); i++) {
				var status_obj = (API.Status)model.get_item (i);
				// Not sure if there can be both the original
				// and a boost of it at the same time.
				if (status_obj.id == status_id || status_obj.formal.id == status_id) {
					model.remove (i);
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
