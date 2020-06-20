using Gee;

public class Tootle.Accounts : GLib.Object {

    private string dir_path;
    private string file_path;

    public ArrayList<InstanceAccount> saved { get; set; default = new ArrayList<InstanceAccount> (); }
    public InstanceAccount? active { get; set; }

    construct {
        dir_path = @"$(GLib.Environment.get_user_config_dir ())/$(app.application_id)";
        file_path = @"$dir_path/accounts.json";
    }

    public void switch_account (int id) {
        var acc = saved.@get (id);
        info (@"Switching to account: $(acc.handle)...");
        new Request.GET ("/api/v1/accounts/verify_credentials")
            .with_account (acc)
            .then ((sess, mess) => {
                var node = network.parse_node (mess);
                var updated = API.Account.from (node);
                acc.patch (updated);
                info ("OK: Token is valid");
                active = acc;
                settings.current_account = id;
            })
            .on_error ((code, reason) => {
                warning ("Token invalid!");
                network.on_show_error (code, _("This instance has invalidated this session. Please sign in again.\n\n%s").printf (reason));
            })
            .exec ();
    }

    public void add (InstanceAccount account) {
        info (@"Adding new account: $(account.handle)");
        saved.add (account);
        save ();
        switch_account (saved.size - 1);
        account.subscribe ();
    }

    public void remove (InstanceAccount account) {
        account.unsubscribe ();
        saved.remove (account);
        saved.notify_property ("size");

        if (saved.size < 1)
            active = null;
        else {
            var id = settings.current_account - 1;
            if (id > saved.size - 1)
                id = saved.size - 1;
            else if (id < saved.size - 1)
                id = 0;
            switch_account (id);
        }
        save ();

        if (is_empty ())
            window.open_view (new Views.NewAccount (false));
    }

    public bool is_empty () {
        return saved.size == 0;
    }

    public void init () {
        save (false);
        load ();

        if (saved.size < 1)
            window.open_view (new Views.NewAccount (false));
        else
            switch_account (settings.current_account);
    }

    public void save (bool overwrite = true) {
        try {
            var dir = File.new_for_path (dir_path);
            if (!dir.query_exists ())
                dir.make_directory ();

            var file = File.new_for_path (file_path);
            if (file.query_exists () && !overwrite)
                return;

            var builder = new Json.Builder ();
            builder.begin_array ();
            saved.foreach ((acc) => {
                var node = acc.to_json ();
                builder.add_value (node);
                return true;
            });
            builder.end_array ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            var data = generator.to_data (null);

            if (file.query_exists ())
                file.@delete ();

            FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
            stream.write (data.data);
            info ("Saved accounts");
        }
        catch (Error e){
            warning (e.message);
        }
    }

    private void load () {
        try {
            uint8[] data;
            string etag;
            var file = File.new_for_path (file_path);
            file.load_contents (null, out data, out etag);
            var contents = (string) data;

            var parser = new Json.Parser ();
            parser.load_from_data (contents, -1);
            var array = parser.get_root ().get_array ();

            array.foreach_element ((_arr, _i, node) => {
                var account = InstanceAccount.from (node);
                if (account != null) {
                    saved.add (account);
                    account.subscribe ();
                }
            });
            info (@"Loaded $(saved.size) accounts");
        }
        catch (Error e){
            warning (e.message);
        }
    }

}
