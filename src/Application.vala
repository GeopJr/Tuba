using Gtk;
using Granite;

namespace Tootle{

    public static Application app;
    public static MainWindow window;
    
    public static SettingsManager settings;
    public static AccountManager accounts;
    public static NetManager network;
    public static CacheManager cache;

    public class Application : Granite.Application {
    
        public abstract signal void toast(string title);
        public abstract signal void error(string title, string text);
    
        construct {
            application_id = "com.github.bleakgrey.tootle";
            flags = ApplicationFlags.FLAGS_NONE;
            program_name = "Toot";
            build_version = "0.1.0";
            settings = new SettingsManager ();
            accounts = new AccountManager ();
            network = new NetManager ();
            cache = new CacheManager ();
        }

        public static int main (string[] args) {
            app = new Application ();
            return app.run (args);
        }
        
        protected override void startup () {
            base.startup ();
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.DEBUG;
            window = new MainWindow (this);
        }
        
        protected override void activate () {
            window.present ();
            var has_token = Tootle.accounts.has_access_token();
            if(has_token)
                Tootle.accounts.update_current ();
            else
                Tootle.accounts.switched (null);
        }
    
    }

}
