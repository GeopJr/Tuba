using GLib;
using Gee;

public class Tootle.InstanceAccount : API.Account, IStreamListener {

	public string? backend { set; get; }
	public string? instance { get; set; }
	public string? client_id { get; set; }
	public string? client_secret { get; set; }
	public string? access_token { get; set; }
	public Error? error { get; set; }

	public int64 last_seen_notification { get; set; default = 0; }
	public bool has_unread_notifications { get; set; default = false; }
	public ArrayList<API.Notification> cached_notifications { get; set; default = new ArrayList<API.Notification> (); }

	protected string? stream;

	public new string handle {
		owned get { return @"@$username@$domain"; }
	}

	construct {
		on_notification.connect (show_notification);
	}

	public InstanceAccount.empty (string instance){
		Object (id: "", instance: instance);
	}
	~InstanceAccount () {
		unsubscribe ();
	}

	public bool is_current () {
		return accounts.active.access_token == access_token;
	}

	// TODO: This should be IStreamable
	public string get_stream_url () {
		return @"$instance/api/v1/streaming/?stream=user&access_token=$access_token";
	}

	public void subscribe () {
		streams.subscribe (get_stream_url (), this, out stream);
	}

	public void unsubscribe () {
		streams.unsubscribe (stream, this);
	}

	public async void verify_credentials () throws Error {
		var req = new Request.GET ("/api/v1/accounts/verify_credentials").with_account (this);
		yield req.await ();

		var node = network.parse_node (req);
		var updated = API.Account.from (node);
		patch (updated);

		message (@"$handle: profile updated");
	}

	public async Entity resolve (string url) throws Error {
		message (@"Resolving URL: \"$url\"...");
		var results = yield API.SearchResults.request (url, this);
		var entity = results.first ();
		message (@"Found $(entity.get_class ().get_name ())");
		return entity;
	}

	// TODO: notification actions
	void show_notification (API.Notification obj) {
		var title = HtmlUtils.remove_tags (obj.kind.get_desc (obj.account));
		var notification = new GLib.Notification (title);
		if (obj.status != null) {
			var body = "";
			body += domain;
			body += "\n";
			body += HtmlUtils.remove_tags (obj.status.content);
			notification.set_body (body);
		}

		app.send_notification (app.application_id + ":" + obj.id.to_string (), notification);
	}

}
