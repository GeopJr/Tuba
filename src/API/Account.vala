public class Tootle.Account{

    public int64 id;
    public string username;
    public string acct;
    public string display_name;
    public string note;
    public string avatar;
    public string url;

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
        account.url = obj.get_string_member ("url");
    
        return account;
    }

}
