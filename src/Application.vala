using Gtk;
using Granite;

namespace Tootle{

    public static Application app;
    public static MainWindow? window;
    public static Window window_dummy;
    
    public static SettingsManager settings;
    public static AccountManager accounts;
    public static NetManager network;
    public static ImageCache image_cache;

    public class Application : Granite.Application {
    
        public abstract signal void refresh ();
        public abstract signal void toast (string title);
        public abstract signal void error (string title, string text);
    
        construct {
            application_id = "com.github.bleakgrey.tootle";
            flags = ApplicationFlags.FLAGS_NONE;
            program_name = "Tootle";
            build_version = "0.1.0";
        }

        public static int main (string[] args) {
            Gtk.init (ref args);
            app = new Application ();
            
            settings = new SettingsManager ();
            accounts = new AccountManager ();
            network = new NetManager ();
            image_cache = new ImageCache ();
            
            return app.run (args);
        }
        
        protected override void startup () {
            base.startup ();
            
            window_dummy = new Window ();
            add_window (window_dummy);
        }
        
        protected override void activate () {
            if (window != null) {
                debug ("Reopening window");
                window.present ();
            }
            else {
                debug ("Creating new window");
                window = new MainWindow (this);
                window.present ();
            }
        }
    
    }

}
