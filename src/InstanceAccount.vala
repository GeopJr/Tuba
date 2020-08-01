using GLib;
using Gee;

public class Tootle.InstanceAccount : API.Account, IStreamListener {

	public string instance { get; set; }
	public string client_id { get; set; }
	public string client_secret { get; set; }
	public string access_token { get; set; }

	public int64 last_seen_notification { get; set; default = 0; }
	public bool has_unread_notifications { get; set; default = false; }
	public ArrayList<API.Notification> cached_notifications { get; set; default = new ArrayList<API.Notification> (); }

	protected string? stream;

	public new string handle {
		owned get { return @"@$username@$short_instance"; }
	}
	public string short_instance {
		owned get {
			return instance
				.replace ("https://", "")
				.replace ("/","");
		}
	}

	public static InstanceAccount from (Json.Node node) throws Error {
		return Entity.from_json (typeof (InstanceAccount), node) as InstanceAccount;
	}

	public InstanceAccount () {
		on_notification.connect (show_notification);
	}
	~InstanceAccount () {
		unsubscribe ();
	}

	public InstanceAccount.empty (string instance){
		Object (id: "", instance: instance);
	}

	public InstanceAccount.from_account (API.Account account) {
		Object (id: account.id);
		patch (account);
	}

	public bool is_current () {
		return accounts.active.access_token == access_token;
	}

	public string get_stream_url () {
		return @"$instance/api/v1/streaming/?stream=user&access_token=$access_token";
	}

	public void subscribe () {
		streams.subscribe (get_stream_url (), this, out stream);
	}

	public void unsubscribe () {
		streams.unsubscribe (stream, this);
	}

	public async Entity resolve (string url) throws Error {
		message (@"Resolving URL: \"$url\"...");
		var results = yield API.SearchResults.request (url, this);
		var entity = results.first ();
		message (@"Found $(entity.get_class ().get_name ())");
		return entity;
	}

	void show_notification (API.Notification obj) {
		var title = Html.remove_tags (obj.kind.get_desc (obj.account));
		var notification = new GLib.Notification (title);
		if (obj.status != null) {
			var body = "";
			body += short_instance;
			body += "\n";
			body += Html.remove_tags (obj.status.content);
			notification.set_body (body);
		}

		app.send_notification (app.application_id + ":" + obj.id.to_string (), notification);

		if (obj.kind == API.NotificationType.WATCHLIST) {
			cached_notifications.add (obj);
			accounts.save ();
		}
	}

}
