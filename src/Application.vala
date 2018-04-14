using Gtk;
using Granite;

namespace Tootle{

    public static Application app;
    public static MainWindow window;

    public class Application : Granite.Application {
    
        public abstract signal void state_updated();
        public abstract signal void toast(string title);
        public abstract signal void error(string error);
    
        construct {
            application_id = "com.github.bleakgrey.tootle";
            flags = ApplicationFlags.FLAGS_NONE;
            program_name = "Toot";
            build_version = "0.1.0";
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
        }
    
    }

}
