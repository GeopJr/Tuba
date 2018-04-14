using GLib;

public class Tootle.AccountManager : Object{

    private static Settings settings;
    private static AccountManager _instance;
    public static AccountManager instance{
        get{
            if(_instance == null)
                _instance = new AccountManager();
            return _instance;
        }
    }

    construct{
        settings = Settings.instance;
    }

    public AccountManager(){
        Object();
    }

    public bool has_client_tokens(){
        var client_id = settings.client_id;
        var client_secret = settings.client_secret;

        return !(client_id == "null" || client_secret == "null");
    }

    public bool has_access_token (){
        return settings.access_token != "null";
    }

    public void request_auth_code (string client_id){
        var pars = "?scope=read%20write%20follow";
        pars += "&response_type=code";
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&client_id=" +client_id;
        
        try {
            AppInfo.launch_default_for_uri (settings.instance_url + "/oauth/authorize" + pars, null);
        }
        catch (GLib.Error e){
            warning (e.message);
        }
    }

    public Soup.Message request_client_tokens(){
        var pars = "?client_name=Tootle";
        pars += "&redirect_uris=urn:ietf:wg:oauth:2.0:oob";
        pars += "&scopes=read%20write%20follow";

        var msg = new Soup.Message("POST", settings.instance_url + "/api/v1/apps" + pars);
        NetManager.instance.queue(msg, (sess, mess) => {
            try{
                var root = NetManager.parse (mess);
                var client_id = root.get_string_member ("client_id");
                var client_secret = root.get_string_member ("client_secret");
                settings.client_id = client_id;
                settings.client_secret = client_secret;
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
        var pars = "?client_id=" + settings.client_id;
        pars += "&client_secret=" + settings.client_secret;
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&grant_type=authorization_code";
        pars += "&code=" + code;

        var msg = new Soup.Message("POST", settings.instance_url + "/oauth/token" + pars);
        NetManager.instance.queue(msg, (sess, mess) => {
            try{
                var root = NetManager.parse (mess);
                var access_token = root.get_string_member ("access_token");
                settings.access_token = access_token;
                debug ("Got access token");
                Tootle.app.state_updated ();
            }
            catch (GLib.Error e) {
                warning ("Can't get access token");
                warning (e.message);
            }
        });
        return msg;
    }

}
