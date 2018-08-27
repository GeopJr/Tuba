using Gtk;
using Granite;

namespace Tootle{

    public static Application app;
    public static MainWindow? window;
    public static Window window_dummy;
    
    public static Settings settings;
    public static Accounts accounts;
    public static Network network;
    public static ImageCache image_cache;
    public static Watchlist watchlist;

    public class Application : Granite.Application {
    
        public abstract signal void refresh ();
        public abstract signal void toast (string title);
        public abstract signal void error (string title, string text);

        const GLib.ActionEntry[] app_entries = {
            {"compose-toot",    compose_toot_activated          },
            {"back",            back_activated                  },
            {"refresh",         refresh_activated               },
            {"switch-timeline", switch_timeline_activated, "i"  }
        };
    
        construct {
            application_id = "com.github.bleakgrey.tootle";
            flags = ApplicationFlags.FLAGS_NONE;
            program_name = "Tootle";
            build_version = "0.1.5";
        }

        public static int main (string[] args) {
            Gtk.init (ref args);
            app = new Application ();
            return app.run (args);
        }
        
        protected override void startup () {
            base.startup ();
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;
            
            settings = new Settings ();
            accounts = new Accounts ();
            network = new Network ();
            image_cache = new ImageCache ();
            watchlist = new Watchlist ();
            accounts.init ();
            
            app.error.connect (app.on_error);
            
            window_dummy = new Window ();
            add_window (window_dummy);

            this.set_accels_for_action ("app.compose-toot", {"<Ctrl>T"});
            this.set_accels_for_action ("app.back", {"<Alt>BackSpace", "<Alt>Left"});
            this.set_accels_for_action ("app.refresh", {"<Ctrl>R", "F5"});
            this.set_accels_for_action ("app.switch-timeline(0)", {"<Alt>1"});
            this.set_accels_for_action ("app.switch-timeline(1)", {"<Alt>2"});
            this.set_accels_for_action ("app.switch-timeline(2)", {"<Alt>3"});
            this.set_accels_for_action ("app.switch-timeline(3)", {"<Alt>4"});

            this.add_action_entries (app_entries, this);
        }
        
        protected override void activate () {
            if (window != null)
                return;
            
            debug ("Creating new window");
            if (accounts.is_empty ())
                NewAccountDialog.open ();
            else {
                window = new MainWindow (this);
                window.present ();
            }
        }
        
        protected void on_error (string title, string msg){
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (title, msg, "dialog-warning");
            message_dialog.transient_for = window;
            message_dialog.run ();
            message_dialog.destroy ();
        }

        private void compose_toot_activated () {
            PostDialog.open ();
        }

        private void back_activated () {
            window.back ();
        }

        private void refresh_activated () {
            refresh ();
        }

        private void switch_timeline_activated (SimpleAction a, Variant? parameter) {
            int32 timeline_no = parameter.get_int32 ();
            window.switch_timeline (timeline_no);
        }
    
    }

}
