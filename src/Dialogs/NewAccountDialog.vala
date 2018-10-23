using Gtk;
using Tootle;

public class Tootle.NewAccountDialog : Gtk.Dialog {

    private static NewAccountDialog dialog;

    private Gtk.Grid grid;
    private Gtk.Button button_done;
    private Gtk.Image logo;
    private Gtk.Entry instance_entry;
    private Gtk.Label instance_register;
    private Gtk.Label code_name;
    private Gtk.Entry code_entry;

    private string? instance;
    private string? client_id;
    private string? client_secret;
    private string? code;
    private string? token;
    private string? username;

    public NewAccountDialog () {
        border_width = 6;
        deletable = true;
        resizable = false;
        title = _("New Account");
        transient_for = window;
        
        logo = new Image.from_resource ("/com/github/bleakgrey/tootle/logo128");
        logo.halign = Gtk.Align.CENTER;
        logo.hexpand = true;
        logo.margin_bottom = 24;
        
        instance_entry = new Entry ();
        instance_entry.width_chars = 30;
        
        instance_register = new Label ("<a href=\"https://joinmastodon.org/\">%s</a>".printf (_("What's an instance?")));
        instance_register.halign = Gtk.Align.END;
        instance_register.set_use_markup (true);
        
        code_name = new AlignedLabel (_("Code:"));
        
        code_entry = new Entry ();
        code_entry.secondary_icon_name = "dialog-question-symbolic";
        code_entry.secondary_icon_tooltip_text = _("Paste your instance authorization code here");
        code_entry.secondary_icon_activatable = false;
        
        button_done = new Gtk.Button.with_label (_("Add Account"));
        button_done.clicked.connect (on_done_clicked);
        button_done.halign = Gtk.Align.END;
        button_done.margin_top = 24;
        
        grid = new Gtk.Grid ();
        grid.column_spacing = 12;
        grid.row_spacing = 6;
        grid.hexpand = true;
        grid.halign = Gtk.Align.CENTER;
        grid.attach (logo, 0, 0, 2, 1);
        grid.attach (new AlignedLabel (_("Instance:")), 0, 1);
        grid.attach (instance_entry, 1, 1);
        grid.attach (code_name, 0, 3);
        grid.attach (code_entry, 1, 3);
        grid.attach (instance_register, 1, 5);
        grid.attach (button_done, 1, 10);
        
        var content = get_content_area () as Gtk.Box;
        content.pack_start (grid, false, false, 0);
        
        destroy.connect (() => {
            dialog = null;
            
            if (accounts.is_empty ())
                app.remove_window (window_dummy);
        });
        
        show_all ();
        clear ();
    }
    
    private void clear () {
        code_name.hide ();
        code_entry.hide ();
        code_entry.text = "";
        client_id = client_secret = code = token = null;
    }
    
    private void on_done_clicked () {
        instance = "https://" + instance_entry.text
            .replace ("/", "")
            .replace (":", "")
            .replace ("https", "")
            .replace ("http", "");
        code = code_entry.text;
            
        if (this.client_id == null || this.client_secret == null) {
            request_client_tokens ();
            return;
        }
        
        if (code == "")
            app.error (_("Error"), _("Please paste valid instance authorization code"));
        else
            try_auth (code);
    }

    private bool show_error (Soup.Message msg) {
        if (msg.status_code != Soup.Status.OK) {
            var phrase = Soup.Status.get_phrase (msg.status_code);
            app.error (_("Network Error"), phrase);
            return true;
        }
        return false;
    }

    private void request_client_tokens (){
        var pars = "?client_name=Tootle";
        pars += "&redirect_uris=urn:ietf:wg:oauth:2.0:oob";
        pars += "&website=https://github.com/bleakgrey/tootle";
        pars += "&scopes=read%20write%20follow";

        grid.sensitive = false;
        var msg = new Soup.Message ("POST", "%s/api/v1/apps%s".printf (instance, pars));
        msg.finished.connect (() => {
            grid.sensitive = true;
            if (show_error (msg)) return;
            
            var root = network.parse (msg);
            var id = root.get_string_member ("client_id");
            var secret = root.get_string_member ("client_secret");
            client_id = id;
            client_secret = secret;
            
            info ("Received tokens from %s", instance);
            request_auth_code ();
            code_name.show ();
            code_entry.show ();
        });
        network.queue_custom (msg);
    }
    
    private void request_auth_code (){
        var pars = "?scope=read%20write%20follow";
        pars += "&response_type=code";
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&client_id=" + client_id;
        
        info ("Requesting auth token");
        Desktop.open_uri ("%s/oauth/authorize%s".printf (instance, pars));
    }
    
    private void try_auth (string code){
        var pars = "?client_id=" + client_id;
        pars += "&client_secret=" + client_secret;
        pars += "&redirect_uri=urn:ietf:wg:oauth:2.0:oob";
        pars += "&grant_type=authorization_code";
        pars += "&code=" + code;

        var msg = new Soup.Message ("POST", "%s/oauth/token%s".printf (instance, pars));
        msg.finished.connect (() => {
            try{
                if (show_error (msg)) return;
                var root = network.parse (msg);
                token = root.get_string_member ("access_token");
                
                debug ("Got access token");
                get_username ();
            }
            catch (GLib.Error e) {
                warning ("Can't get access token");
                warning (e.message);
            }
        });
        network.queue_custom (msg);
    }
    
    private void get_username () {
        var msg = new Soup.Message("GET", "%s/api/v1/accounts/verify_credentials".printf (instance));
        msg.request_headers.append ("Authorization", "Bearer " + token);
        msg.finished.connect (() => {
            try{
                if (show_error (msg)) return;
                var root = network.parse (msg);
                username = root.get_string_member ("username");
                
                add_account ();
                window.show ();
                window.present ();
                destroy ();
            }
            catch (GLib.Error e) {
                warning ("Can't get username");
                warning (e.message);
            }
        });
        network.queue_custom (msg);
    }
    
    private void add_account () {
        var account = new InstanceAccount ();
        account.username = username;
        account.instance = instance;
        account.client_id = client_id;
        account.client_secret = client_secret;
        account.token = token;
        accounts.add (account);
        app.activate ();
    }

    public static void open () {
        if (dialog == null)
            dialog = new NewAccountDialog ();
    }

}
