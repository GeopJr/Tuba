public class Tooth.API.Account : Entity, Widgetizable {

    public string id { get; set; }
    public string username { get; set; }
    public string acct { get; set; }
    public string? _display_name = null;
    public string display_name {
        set {
            this._display_name = value;
        }
    	get {
    		return (_display_name == null || _display_name == "") ? username : _display_name;
    	}
    }
    public string note { get; set; }
    public string header { get; set; }
    public string avatar { get; set; }
    public string url { get; set; }
    public string created_at { get; set; }
    public int64 followers_count { get; set; }
    public int64 following_count { get; set; }
    public int64 statuses_count { get; set; }
    public Gee.ArrayList<API.AccountField>? fields { get; set; default = null; }

    public string handle {
        owned get {
            return "@" + acct;
        }
    }
	public string domain {
		owned get {
			var uri = new Soup.URI (url);
			return uri.get_host ();
		}
	}

	public static Account from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Account), node) as API.Account;
	}

    public bool is_self () {
        return id == accounts.active.id;
    }

	public override bool is_local (InstanceAccount account) {
		return account.domain in url;
	}

    public override Gtk.Widget to_widget () {
        var status = new API.Status.from_account (this);
        return new Widgets.Status (status);
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
				account.resolve.end (res).open ();
			});
		}
	}

}
