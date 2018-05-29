public class Tootle.Account{

    public abstract signal void updated ();

    public int64 id;
    public string username;
    public string acct;
    public string display_name;
    public string note;
    public string header;
    public string avatar;
    public string url;
    public string created_at;
    public int64 followers_count;
    public int64 following_count;
    public int64 statuses_count;
    
    public Relationship? rs;

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
        account.created_at = obj.get_string_member ("created_at");
        
        account.followers_count = obj.get_int_member ("followers_count");
        account.following_count = obj.get_int_member ("following_count");
        account.statuses_count = obj.get_int_member ("statuses_count");
        
        if (obj.has_member ("fields")) {
            obj.get_array_member ("fields").foreach_element ((array, i, node) => {
                var field_obj = node.get_object ();
                var field_name = field_obj.get_string_member ("name");
                var field_val = field_obj.get_string_member ("value");
                account.note += "\n";
                account.note += field_name + ": ";
                account.note += field_val;
            });
        }
    
        return account;
    }
    
    public bool is_self (){
        return id == Tootle.accounts.current.id;
    }

    public Soup.Message get_relationship (){
        var url = "%s/api/v1/accounts/relationships?id=%lld".printf (Tootle.accounts.formal.instance, id);
        var msg = new Soup.Message("GET", url);
        msg.priority = Soup.MessagePriority.HIGH;
        Tootle.network.queue (msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse_array (mess).get_object_element (0);
                rs = Relationship.parse (root);
                updated ();
            }
            catch (GLib.Error e) {
                warning ("Can't get account relationship:");
                warning (e.message);
            }
        });
        return msg;
    }
    
    public Soup.Message set_following (bool follow = true){
        var action = follow ? "follow" : "unfollow"; 
        var url = "%s/api/v1/accounts/%lld/%s".printf (Tootle.accounts.formal.instance, id, action);
        var msg = new Soup.Message("POST", url);
        msg.priority = Soup.MessagePriority.HIGH;
        Tootle.network.queue (msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                rs = Relationship.parse (root);
                updated ();
            }
            catch (GLib.Error e) {
                Tootle.app.error (_("Error"), e.message);
                warning (e.message);
            }
        });
        return msg;
    }

    public Soup.Message set_muted (bool mute = true){
        var action = mute ? "mute" : "unmute"; 
        var url = "%s/api/v1/accounts/%lld/%s".printf (Tootle.accounts.formal.instance, id, action);
        var msg = new Soup.Message("POST", url);
        msg.priority = Soup.MessagePriority.HIGH;
        Tootle.network.queue (msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                rs = Relationship.parse (root);
                updated ();
            }
            catch (GLib.Error e) {
                Tootle.app.error (_("Error"), e.message);
                warning (e.message);
            }
        });
        return msg;
    }
    
    public Soup.Message set_blocked (bool block = true){
        var action = block ? "block" : "unblock"; 
        var url = "%s/api/v1/accounts/%lld/%s".printf (Tootle.accounts.formal.instance, id, action);
        var msg = new Soup.Message("POST", url);
        msg.priority = Soup.MessagePriority.HIGH;
        Tootle.network.queue (msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                rs = Relationship.parse (root);
                updated ();
            }
            catch (GLib.Error e) {
                Tootle.app.error (_("Error"), e.message);
                warning (e.message);
            }
        });
        return msg;
    }

}
