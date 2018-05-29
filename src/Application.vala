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
            accounts.init ();
                                    
            app.error.connect (app.on_error);
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
                if (!accounts.is_empty ())
                    window.present ();
                else
                    NewAccountDialog.open ();
            }
            else {
                debug ("Creating new window");
                if (accounts.is_empty ())
                    NewAccountDialog.open ();
                else {
                    window = new MainWindow (this);
                    window.present ();
                }
            }
        }
        
        protected void on_error (string title, string msg){
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (title, msg, "dialog-warning");
            message_dialog.transient_for = window;
            message_dialog.run ();
            message_dialog.destroy ();
        }
    
    }

}
