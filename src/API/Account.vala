public class Tootle.API.Account : Entity, Widgetizable {

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
    public Relationship? rs { get; set; default = null; }
    public Gee.ArrayList<API.AccountField>? fields { get; set; default = null; }

    public string handle {
        owned get {
            return "@" + acct;
        }
    }

	public static Account from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Account), node) as API.Account;
	}

    public bool is_self () {
        return id == accounts.active.id;
    }

    public override Gtk.Widget to_widget () {
        var status = new API.Status.from_account (this);
        return new Widgets.Status (status);
    }

    public Request get_relationship () {
    	return new Request.GET ("/api/v1/accounts/relationships")
    		.with_account (accounts.active)
    		.with_param ("id", id.to_string ())
    		.then_parse_array (node => {
    		    rs = API.Relationship.from (node);
    		})
    		.on_error (network.on_error)
    		.exec ();
    }

    public Request set_following (bool state = true) {
        var action = state ? "follow" : "unfollow";
        return new Request.POST (@"/api/v1/accounts/$id/$action")
            .with_account (accounts.active)
            .then ((sess, msg) => {
                var node = network.parse_node (msg);
                rs = API.Relationship.from (node);
            })
    		.on_error (network.on_error)
    		.exec ();
    }

    public Request set_muted (bool state = true) {
        var action = state ? "mute" : "unmute";
        return new Request.POST (@"/api/v1/accounts/$id/$action")
            .with_account (accounts.active)
            .then ((sess, msg) => {
                var node = network.parse_node (msg);
                rs = API.Relationship.from (node);
            })
    		.on_error (network.on_error)
    		.exec ();
    }

    public Request set_blocked (bool state = true) {
        var action = state ? "block" : "unblock";
        return new Request.POST (@"/api/v1/accounts/$id/$action")
            .with_account (accounts.active)
            .then ((sess, msg) => {
                var node = network.parse_node (msg);
                rs = API.Relationship.from (node);
            })
    		.on_error (network.on_error)
    		.exec ();
    }

}
