public class Tootle.Settings : Granite.Services.Settings {

        private static Settings? _instance;
        public static Settings instance {
            get{
                if (_instance == null)
                    _instance = new Settings ();
                return _instance;
            }
        }
        
        public string client_id { get; set; }
        public string client_secret { get; set; }
        public string access_token { get; set; }
        public string refresh_token { get; set; }
        public string instance_url { get; set; }

        public void clear_account (){
            access_token = "null";
            refresh_token = "null";
            instance_url = "null";
            debug ("Removed current account");
        }

        private Settings () {
            base ("com.github.bleakgrey.tootle");
        }

}
