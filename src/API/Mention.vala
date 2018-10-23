public class Tootle.Mention{

    public int64 id;
    public string username;
    public string acct;
    public string url;

    public Mention (int64 _id){
        id = _id;
    }
    
    public Mention.from_account (Account account){
        id = account.id;
        username = account.username;
        acct = account.acct;
        url = account.url;
    }
    
    public static Mention parse (Json.Object obj){
        var id = int64.parse (obj.get_string_member ("id"));
        var mention = new Mention (id);
        
        mention.username = obj.get_string_member ("username");
        mention.acct = obj.get_string_member ("acct");
        mention.url = obj.get_string_member ("url");
        
        return mention;
    }

}
