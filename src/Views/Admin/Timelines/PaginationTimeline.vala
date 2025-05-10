public class Tuba.Views.Admin.Timeline.PaginationTimeline : Gtk.Box {
	~PaginationTimeline () {
		debug ("Destroying PaginationTimeline");
	}

	protected Gtk.ListBox content;
	public string url { get; set; default = ""; }
	public Type accepts { get; set; default = Type.NONE; }
	public bool working { get; set; default = false; }
	public signal void on_error (int code, string message);

	private string? _page_next = null;
	public string? page_next {
		get {
			return _page_next;
		}

		set {
			_page_next = value;
			next_button.sensitive = value != null;
		}
	}

	private string? _page_prev = null;
	public string? page_prev {
		get {
			return _page_prev;
		}

		set {
			_page_prev = value;
			prev_button.sensitive = value != null;
		}
	}

	private Gtk.Button prev_button;
	private Gtk.Button next_button;
	construct {
		this.orientation = Gtk.Orientation.VERTICAL;
		this.spacing = 12;

		content = new Gtk.ListBox () {
			selection_mode = Gtk.SelectionMode.NONE,
			css_classes = { "fake-content", "background" }
		};
		content.row_activated.connect (on_content_item_activated);

		var pagination_buttons = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 12) {
			homogeneous = true,
			hexpand = true,
			margin_bottom = 12
		};
		prev_button = new Gtk.Button.from_icon_name ("tuba-left-large-symbolic") {
			css_classes = {"circular", "flat"},
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Previous Page")
		};
		prev_button.clicked.connect (on_prev);
		pagination_buttons.append (prev_button);

		next_button = new Gtk.Button.from_icon_name ("tuba-right-large-symbolic") {
			css_classes = {"circular", "flat"},
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Next Page")
		};
		next_button.clicked.connect (on_next);
		pagination_buttons.append (next_button);

		this.append (new Adw.Clamp () {
			vexpand = true,
			maximum_size = 670,
			tightening_threshold = 670,
			css_classes = {"ttl-view"},
			child = content
		});
		this.append (pagination_buttons);
	}

	private void on_next () {
		first_page = false;
		url = page_next;
		request_idle ();
	}

	private void on_prev () {
		first_page = false;
		url = page_prev;
		request_idle ();
	}

	bool first_page = true;
	public void get_pages (string? header) {
		page_next = page_prev = null;
		if (header == null) {
			return;
		};

		var pages = header.split (",");
		foreach (var page in pages) {
			var sanitized = page
				.replace ("<", "")
				.replace (">", "")
				.split (";")[0];

			if ("rel=\"prev\"" in page) {
				if (!first_page) page_prev = sanitized;
			} else {
				page_next = sanitized;
			}
		}
	}

	public void request_idle () {
		GLib.Idle.add (request);
	}

	public void reset (string new_url) {
		this.url = new_url;
		first_page = true;
		request_idle ();
	}

	public virtual bool request () {
		if (accepts == Type.NONE) return GLib.Source.REMOVE;
		next_button.sensitive = prev_button.sensitive = false;

		this.working = true;
		new Request.GET (url)
			.with_account (accounts.active)
			.with_ctx (this)
			.with_extra_data (Tuba.Network.ExtraData.RESPONSE_HEADERS)
			.then ((in_stream, headers) => {
				content.remove_all ();
				var parser = Network.get_parser_from_inputstream (in_stream);

				Network.parse_array (parser, node => {
					content.append (on_create_model_widget (Tuba.Helper.Entity.from_json (node, accepts)));
				});

				this.working = false;
				if (headers != null)
					get_pages (headers.get_one ("Link"));
			})
			.on_error ((code, message) => {
				on_error (code, message);
			})
			.exec ();

		return GLib.Source.REMOVE;
	}

	public virtual Gtk.Widget on_create_model_widget (Object obj) {
		var obj_widgetable = obj as BasicWidgetizable;
		if (obj_widgetable == null)
			Process.exit (0);
		try {
			Gtk.Widget widget = obj_widgetable.to_widget ();
			widget.add_css_class ("card");
			widget.add_css_class ("card-spacing");
			widget.focusable = true;

			return widget;
		} catch (Oopsie e) {
			warning (@"Error on_create_model_widget: $(e.message)");
			Process.exit (0);
		}
	}

	public virtual void on_content_item_activated (Gtk.ListBoxRow row) {}
}
