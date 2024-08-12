public class Tuba.API.Account : Entity, Widgetizable, SearchResult {
	public API.Relationship? tuba_rs { get; set; default=null; }
	public string? tuba_search_query { get; set; default = null; }

	public string id { get; set; }
	public string username { get; set; }
	public string acct { get; set; }

	/* internal display name representation */
	private string _display_name = "";
	/* User's display name: Specific display name, or falling back to the
	   nickname */
	public string display_name {
		set {
		_display_name = value;
		}
		get {
			return ( ( _display_name != null && _display_name.length > 0 ) ? _display_name : username );
		}
	}

	public string note { get; set; default=""; }
	public bool locked { get; set; }
	public string header { get; set; }
	public string avatar { get; set; }
	public string url { get; set; }
	public bool bot { get; set; default=false; }
	public string created_at { get; set; }
	public Gee.ArrayList<API.Emoji>? emojis { get; set; }
	public int64 followers_count { get; set; }
	public int64 following_count { get; set; }
	public int64 statuses_count { get; set; }
	public Gee.ArrayList<API.AccountRole>? roles { get; set; default = null; }
	public Gee.ArrayList<API.AccountField>? fields { get; set; default = null; }
	public AccountSource? source { get; set; default = null; }
	public API.AccountRole? role { get; set; default = null; }

	public override Type deserialize_array_type (string prop) {
		switch (prop) {
			case "emojis":
				return typeof (API.Emoji);
			case "fields":
				return typeof (API.AccountField);
			case "roles":
				return typeof (API.AccountRole);
		}

		return base.deserialize_array_type (prop);
	}

	public string handle {
		owned get {
			return "@" + acct;
		}
	}
	public string domain {
		owned get {
			Uri uri;
			try {
				uri = Uri.parse (url, UriFlags.NONE);
			} catch (GLib.UriError e) {
				warning (e.message);
				return "";
			}
			return uri.get_host ();
		}
	}
	public string full_handle {
		owned get {
			return @"@$username@$domain";
		}
	}

	public Gee.HashMap<string, string>? emojis_map {
		owned get {
			return gen_emojis_map ();
		}
	}

	private Gee.HashMap<string, string>? gen_emojis_map () {
		var res = new Gee.HashMap<string, string> ();
		if (emojis != null && emojis.size > 0) {
			emojis.@foreach (e => {
				res.set (e.shortcode, e.url);
				return true;
			});
		}

		return res;
	}

	public static Account from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Account), node) as API.Account;
	}

	public static Request search (string query) throws Error {
		return new Request.GET ("/api/v1/accounts/search")
			.with_account (accounts.active)
			.with_param ("q", query)
			.with_param ("resolve", "false")
			.with_param ("limit", "4");
	}

	public bool is_self () {
		return id == accounts.active.id;
	}

	public override bool is_local (InstanceAccount account) {
		return account.domain in url;
	}

	public override Gtk.Widget to_widget () {
		return new Widgets.Account (this);
	}

	public override void open () {
		var view = new Views.Profile (this);
		app.main_window.open_view (view);
	}

	public override void resolve_open (InstanceAccount account) {
		if (is_local (account))
			open ();
		else {
			account.resolve.begin (url, (obj, res) => {
				try {
					account.resolve.end (res).open ();
				} catch (Error e) {
					warning (@"Error opening account: $(account.handle) - $(e.message)");
				}
			});
		}
	}

	public Request accept_follow_request () {
		return new Request.POST (@"/api/v1/follow_requests/$id/authorize")
			.with_account (accounts.active);
	}

	public Request decline_follow_request () {
		return new Request.POST (@"/api/v1/follow_requests/$id/reject")
			.with_account (accounts.active);
	}
}
