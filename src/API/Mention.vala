public class Tooth.API.Mention : Entity, Widgetizable {

    public string id { get; construct set; }
    public string username { get; construct set; }
    public string acct { get; construct set; }
    public string url { get; construct set; }

    public string handle {
        owned get {
            return "@" + acct;
        }
    }

    public Mention.from_account (API.Account account) {
    	Object (
    		id: account.id,
    		username: account.username,
    		acct: account.acct,
    		url: account.url
    	);
    }

	public override void open () {
		Views.Profile.open_from_id (id);
	}

}
