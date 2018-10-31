using Gtk;
using Granite;

namespace Tootle {

    public static Application app;
    public static MainWindow? window;
    public static Window window_dummy;
    
    public static Settings settings;
    public static Accounts accounts;
    public static Network network;
    public static ImageCache image_cache;
    public static Watchlist watchlist;

    public static bool start_hidden = false;

    public class Application : Granite.Application {
    
        public abstract signal void refresh ();
        public abstract signal void toast (string title);
        public abstract signal void error (string title, string text);

        public const GLib.OptionEntry[] app_options = {
            { "hidden", 0, 0, OptionArg.NONE, ref start_hidden, "Do not show main window on start", null },
            { null }
        };

        public const GLib.ActionEntry[] app_entries = {
            {"compose-toot",    compose_toot_activated          },
            {"back",            back_activated                  },
            {"refresh",         refresh_activated               },
            {"switch-timeline", switch_timeline_activated, "i"  }
        };
    
        construct {
            application_id = "com.github.bleakgrey.tootle";
            flags = ApplicationFlags.FLAGS_NONE;
            program_name = "Tootle";
            build_version = "0.2.0";
        }

        public static int main (string[] args) {
            Gtk.init (ref args);
            
            try {
                var opt_context = new OptionContext ("- Options");
                opt_context.add_main_entries (app_options, null);
                opt_context.parse (ref args);
            }
            catch (GLib.OptionError e) {
                warning (e.message);
            }
            
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

            set_accels_for_action ("app.compose-toot", {"<Ctrl>T"});
            set_accels_for_action ("app.back", {"<Alt>BackSpace", "<Alt>Left"});
            set_accels_for_action ("app.refresh", {"<Ctrl>R", "F5"});
            set_accels_for_action ("app.switch-timeline(0)", {"<Alt>1"});
            set_accels_for_action ("app.switch-timeline(1)", {"<Alt>2"});
            set_accels_for_action ("app.switch-timeline(2)", {"<Alt>3"});
            set_accels_for_action ("app.switch-timeline(3)", {"<Alt>4"});
            add_action_entries (app_entries, this);
        }
        
        protected override void activate () {
            if (window != null) {
                window.present ();
                return;
            }
            
            if (start_hidden) {
                start_hidden = false;
                return;
            }
            
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
