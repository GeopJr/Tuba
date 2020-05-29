using Gtk;
using Gdk;

public class Tootle.Views.Timeline : Views.Base, IAccountListener, IStreamListener {

    public string timeline { get; construct set; }
    public bool is_public { get; construct set; default = false; }

    protected InstanceAccount? account = null;
    protected int limit = 25;
    protected bool is_last_page = false;
    protected string? page_next;
    protected string? page_prev;
    protected string? stream;

    construct {
        app.refresh.connect (on_refresh);
        status_button.clicked.connect (on_refresh);
        connect_account ();
    }
    ~Timeline () {
        streams.unsubscribe (stream, this);
    }

    public override string get_icon () {
        return "user-home-symbolic";
    }

    public override string get_name () {
        return _("Home");
    }

    public override void on_status_added (API.Status status) {
        prepend (status);
    }

    public virtual bool is_status_owned (API.Status status) {
        return status.is_owned ();
    }

    public void prepend (API.Status status) {
        append (status, true);
    }

    public void append (API.Status status, bool first = false) {
        GLib.Idle.add (() => {
            var w = new Widgets.Status (status);
            w.button_press_event.connect (w.open);
            if (!is_status_owned (status))
                w.avatar.button_press_event.connect (w.on_avatar_clicked);

            content.pack_start (w, false, false, 0);
            if (first || status.pinned)
                content.reorder_child (w, 0);

            on_content_changed ();
            return GLib.Source.REMOVE;
        });
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

    public virtual string get_url () {
        if (page_next != null)
            return page_next;

        return @"/api/v1/timelines/$timeline";
    }

    public virtual Request append_params (Request req) {
        return req.with_param ("limit", limit.to_string ());
    }

    public virtual bool request () {
		append_params (new Request.GET (get_url ()))
		.with_account (account)
		.then_parse_array ((node, msg) => {
            var obj = node.get_object ();
            if (obj != null) {
                var status = new API.Status (obj);
                append (status);
            }
            get_pages (msg.response_headers.get_one ("Link"));
        })
		.on_error (on_error)
		.exec ();

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

    public override void on_account_changed (InstanceAccount? acc) {
        account = acc;
		streams.unsubscribe (stream, this);
        streams.subscribe (get_stream_url (), this, out stream);
        on_refresh ();
    }

    protected override bool accepts (ref string event) {
        var allowed_public = true;
        if (is_public)
            allowed_public = settings.live_updates_public;

        return settings.live_updates && allowed_public;
    }

    protected override void on_bottom_reached () {
        if (is_last_page) {
            info ("Last page reached");
            return;
        }
        request ();
    }

}
