using Gtk;
using Gdk;

public class Tootle.Views.Timeline : IAccountListener, IStreamListener, Views.Base {

    public string url { get; construct set; }
    public bool is_public { get; construct set; default = false; }
    public Type accepts { get; set; default = typeof (API.Status); }

    protected InstanceAccount? account = null;

    protected bool is_last_page { get; set; default = false; }
    protected string? page_next { get; set; }
    protected string? page_prev { get; set; }
    protected string? stream = null;

    construct {
        app.refresh.connect (on_refresh);
        status_button.clicked.connect (on_refresh);
        connect_account ();

        on_status_added.connect (add_status);
        on_status_removed.connect (remove_status);
    }
    ~Timeline () {
        streams.unsubscribe (stream, this);
    }

    public virtual bool is_status_owned (API.Status status) {
        return status.is_owned ();
    }

    public void prepend (Widget? w) {
        append (w, true);
    }

    public virtual void append (Widget? w, bool first = false) {
        if (w == null) {
            warning ("Attempted to add an empty widget");
            return;
        }

        if (first)
            content_list.prepend (w);
        else
            content_list.insert (w, -1);

        on_content_changed ();
    }

    public override void clear () {
        this.page_prev = null;
        this.page_next = null;
        this.is_last_page = false;
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

    public virtual bool request () {
		var req = append_params (new Request.GET (get_req_url ()))
		.with_account (account)
		.then_parse_array ((node, msg) => {
		    try {
                var e = Entity.from_json (accepts, node);
                var w = e as Widgetizable;
                append (w.to_widget ());
		    }
		    catch (Error e) {
		        warning (@"Timeline item parse error: $(e.message)");
		    }
        })
		.on_error (on_error);
		req.finished.connect (() => {
		    get_pages (req.response_headers.get_one ("Link"));
		});
		req.exec ();
		return GLib.Source.REMOVE;
    }

    public virtual void on_refresh () {
        status_button.sensitive = false;
        clear ();
        status_message = STATUS_LOADING;
        GLib.Idle.add (request);
    }

    public virtual string? get_stream_url () {
        return null;
    }

    public virtual void on_account_changed (InstanceAccount? acc) {
        account = acc;
		streams.unsubscribe (stream, this);
        streams.subscribe (get_stream_url (), this, out stream);
        on_refresh ();
    }

    protected override void on_bottom_reached () {
        if (is_last_page) {
            info ("Last page reached");
            return;
        }
        request ();
    }

    protected virtual void add_status (API.Status status) {
        var allow_update = true;
        if (is_public)
            allow_update = settings.public_live_updates;

        if (settings.live_updates && allow_update)
            prepend (status.to_widget ());
    }

    protected virtual void remove_status (string id) {
        if (settings.live_updates) {
            content.get_children ().@foreach (w => {
                var sw = w as Widgets.Status;
                if (sw != null && sw.status.id == id)
                    sw.destroy ();
            });
        }
    }

}
