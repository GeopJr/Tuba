public class Tootle.Account{

    public int64 id;
    public string username;
    public string acct;
    public string display_name;
    public string note;
    public string header;
    public string avatar;
    public string url;
    public int64 followers_count;
    public int64 following_count;
    public int64 statuses_count;

    public Account(int64 id){
        this.id = id;
    }
    
    public static Account parse(Json.Object obj) {
        var id = int64.parse (obj.get_string_member ("id"));
        var account = new Account (id);
        
        account.username = obj.get_string_member ("username");
        account.acct = obj.get_string_member ("acct");
        account.display_name = obj.get_string_member ("display_name");
        if (account.display_name == "")
            account.display_name = account.username;
        account.note = obj.get_string_member ("note");
        account.avatar = obj.get_string_member ("avatar");
        account.header = obj.get_string_member ("header");
        account.url = obj.get_string_member ("url");
        
        account.followers_count = obj.get_int_member ("followers_count");
        account.following_count = obj.get_int_member ("following_count");
        account.statuses_count = obj.get_int_member ("statuses_count");
    
        return account;
    }

}
