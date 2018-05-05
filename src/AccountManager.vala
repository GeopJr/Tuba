using GLib;

public class Tootle.AccountManager : Object{

    public abstract signal void switched(Account? account);
    public abstract signal void added(Account account);
    public abstract signal void removed(Account account);

    public Account? current;

    public AccountManager(){
        Object();
    }

    public bool has_client_tokens(){
        var client_id = Tootle.settings.client_id;
        var client_secret = Tootle.settings.client_secret;

        return !(client_id == "null" || client_secret == "null");
    }

    public bool has_access_token (){
        return Tootle.settings.access_token != "null";
    }

    public void request_auth_code (string client_id){
        var pars = "?scope=read%20write%20follow";
        pars += "&response_type=code";
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&client_id=" +client_id;
        
        try {
            AppInfo.launch_default_for_uri ("%s/oauth/authorize%s".printf (Tootle.settings.instance_url, pars), null);
        }
        catch (GLib.Error e){
            warning (e.message);
        }
    }

    public Soup.Message request_client_tokens(){
        var pars = "?client_name=Tootle";
        pars += "&redirect_uris=urn:ietf:wg:oauth:2.0:oob";
        pars += "&website=https://github.com/bleakgrey/tootle";
        pars += "&scopes=read%20write%20follow";

        var msg = new Soup.Message("POST", "%s/api/v1/apps%s".printf (Tootle.settings.instance_url, pars));
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                var client_id = root.get_string_member ("client_id");
                var client_secret = root.get_string_member ("client_secret");
                Tootle.settings.client_id = client_id;
                Tootle.settings.client_secret = client_secret;
                debug ("Received tokens");
                
                request_auth_code (client_id);
            }
            catch (GLib.Error e) {
                warning ("Can't request client secret.");
                warning (e.message);
            }
        });
        return msg;
    }
    
    public Soup.Message try_auth (string code){
        var pars = "?client_id=" + Tootle.settings.client_id;
        pars += "&client_secret=" + Tootle.settings.client_secret;
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&grant_type=authorization_code";
        pars += "&code=" + code;

        var msg = new Soup.Message("POST", "%s/oauth/token%s".printf (Tootle.settings.instance_url, pars));
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                var access_token = root.get_string_member ("access_token");
                Tootle.settings.access_token = access_token;
                debug ("Got access token");
                request_current ();
            }
            catch (GLib.Error e) {
                warning ("Can't get access token");
                warning (e.message);
            }
        });
        return msg;
    }
    
    public Soup.Message request_current (){
        var msg = new Soup.Message("GET", "%s/api/v1/accounts/verify_credentials".printf (Tootle.settings.instance_url));
        Tootle.network.queue(msg, (sess, mess) => {
            try{
                var root = Tootle.network.parse (mess);
                current = Account.parse(root);
                switched (current);
            }
            catch (GLib.Error e) {
                warning ("Can't get current user");
                warning (e.message);
            }
        });
        return msg;
    }
    
    public void logout (){
        current = null;
        Tootle.settings.access_token = "null";
        switched (null);
    }
    
    public void init (){
        if(has_access_token())
            request_current ();
        else
            switched (null);
    }

}
