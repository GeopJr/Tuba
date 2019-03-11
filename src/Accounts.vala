using GLib;

public class Tootle.Accounts : Object {

    private string dir_path;
    private string file_path;

    public signal void switched (API.Account? account);
    public signal void updated (GenericArray<InstanceAccount> accounts);

    public GenericArray<InstanceAccount> saved_accounts = new GenericArray<InstanceAccount> ();
    public InstanceAccount? formal {get; set;}
    public API.Account? current {get; set;}

    public Accounts () {
        dir_path = "%s/%s".printf (GLib.Environment.get_user_config_dir (), app.application_id);
        file_path = "%s/%s".printf (dir_path, "accounts.json");
    }

    public void switch_account (int id) {
        debug ("Switching to #%i", id);
        settings.current_account = id;
        formal = saved_accounts.@get (id);
        var msg = new Soup.Message ("GET", "%s/api/v1/accounts/verify_credentials".printf (accounts.formal.instance));
        network.queue (msg, (sess, mess) => {
            try {
                var root = network.parse (mess);
                current = API.Account.parse (root);
                switched (current);
                updated (saved_accounts);
            }
            catch (GLib.Error e) {
                warning ("Can't login into %s", formal.instance);
                warning (e.message);
            }
        });
    }

    public void add (InstanceAccount account) {
        debug ("Adding account for %s at %s", account.username, account.instance);
        saved_accounts.add (account);
        save ();
        updated (saved_accounts);
        switch_account (saved_accounts.length - 1);
        account.start_notificator ();
    }

    public void remove (int i) {
        var account = saved_accounts.@get (i);
        account.close_notificator ();

        saved_accounts.remove_index (i);
        if (saved_accounts.length < 1)
            switched (null);
        else {
            var id = settings.current_account - 1;
            if (id > saved_accounts.length - 1)
                id = saved_accounts.length - 1;
            else if (id < saved_accounts.length - 1)
                id = 0;
            switch_account (id);
        }
        save ();
        updated (saved_accounts);

        if (is_empty ()) {
            window.destroy ();
            Dialogs.NewAccount.open ();
        }
    }

    public bool is_empty () {
        return saved_accounts.length == 0;
    }

    public void init () {
        save (false);
        load ();

        if (saved_accounts.length < 1)
            Dialogs.NewAccount.open ();
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
            saved_accounts.foreach ((acc) => {
                var node = acc.serialize ();
                builder.add_value (node);
            });
            builder.end_array ();

            var generator = new Json.Generator ();
            generator.set_root (builder.get_root ());
            var data = generator.to_data (null);

            if (file.query_exists ())
                file.@delete ();

            FileOutputStream stream = file.create (FileCreateFlags.PRIVATE);
            stream.write (data.data);
        }
        catch (GLib.Error e){
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

            saved_accounts = new GenericArray<InstanceAccount> ();
            array.foreach_element ((_arr, _i, node) => {
                var obj = node.get_object ();
                var account = InstanceAccount.parse (obj);
                if (account != null) {
                    saved_accounts.add (account);
                    account.start_notificator ();
                }
            });
            debug ("Loaded %i saved accounts", saved_accounts.length);
            updated (saved_accounts);
        }
        catch (GLib.Error e){
            warning (e.message);
        }
    }

}
