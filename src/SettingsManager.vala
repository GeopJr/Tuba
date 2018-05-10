public class Tootle.SettingsManager : Granite.Services.Settings {

    public string client_id { get; set; }
    public string client_secret { get; set; }
    public string access_token { get; set; }
    public string refresh_token { get; set; }
    public string instance_url { get; set; }
    public bool always_online { get; set; }
    public bool cache { get; set; }

    public void clear_account (){
        access_token = "null";
        refresh_token = "null";
        instance_url = "null";
        debug ("Removed current account");
    }

    public SettingsManager () {
        base ("com.github.bleakgrey.tootle");
    }

}
