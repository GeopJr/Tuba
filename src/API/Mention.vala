public class Tootle.API.Mention : Entity {

    public string id { get; construct set; }
    public string username { get; construct set; }
    public string acct { get; construct set; }
    public string url { get; construct set; }

    public Mention.from_account (API.Account account) {
    	Object (
    		id: account.id,
    		username: account.username,
    		acct: account.acct,
    		url: account.url
    	);
    }

}
