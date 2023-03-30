using Secret;

public class Tuba.SecretAccountStore : AccountStore {

	const string VERSION = "1";

	Secret.Schema schema;
	GLib.HashTable<string,SchemaAttributeType> schema_attributes;

	public override void init () throws GLib.Error {
		message (@"Using libsecret v$(Secret.MAJOR_VERSION).$(Secret.MINOR_VERSION).$(Secret.MICRO_VERSION)");

		schema_attributes = new GLib.HashTable<string,SchemaAttributeType> (str_hash, str_equal);
		schema_attributes["login"] = SchemaAttributeType.STRING;
		schema_attributes["version"] = SchemaAttributeType.STRING;
		schema = new Secret.Schema.newv (
			Build.DOMAIN,
			Secret.SchemaFlags.DONT_MATCH_NAME,
			schema_attributes
		);

		base.init ();
	}

	public override void load () throws GLib.Error {
		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["version"] = VERSION;

		var secrets = Secret.password_searchv_sync (
			schema,
			attrs,
			Secret.SearchFlags.ALL | Secret.SearchFlags.UNLOCK,
			null
		);

		secrets.foreach (item => {
			var account = secret_to_account (item);
			if (account != null && account.id != "") {
				new Request.GET (@"/api/v1/accounts/$(account.id)")
					.with_account (account)
					.then ((sess, msg, in_stream) => {
						var node = network.parse_node (in_stream);
						var acc = API.Account.from (node);

						if (account.display_name != acc.display_name || account.avatar != acc.avatar) {
							account.display_name = acc.display_name;
							account.avatar = acc.avatar;

							account_to_secret (account);
						}
					})
					.exec ();
					saved.add (account);
					account.added ();
			}
		});
		changed (saved);

		message (@"Loaded $(saved.size) accounts");
	}

	public override void save () throws GLib.Error {
		saved.foreach (account => {
			account_to_secret (account);
			return true;
		});
		message (@"Saved $(saved.size) accounts");
	}

	public override void remove (InstanceAccount account) throws GLib.Error {
		base.remove (account);

		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["version"] = VERSION;
		attrs["login"] = account.handle;

		Secret.password_clearv_sync (
			schema,
			attrs,
			null
		);
	}

	void account_to_secret (InstanceAccount account) {
		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["login"] = account.handle;
		attrs["version"] = VERSION;

		var generator = new Json.Generator ();
		account.instance_info = null;
		generator.set_root (account.to_json ());
		var secret = generator.to_data (null);
		// translators: The variable is the backend like "Mastodon"
		var label = _("%s Account").printf (account.backend);

		try {
			Secret.password_storev_sync (
				schema,
				attrs,
				Secret.COLLECTION_DEFAULT,
				label,
				secret,
				null
			);
		}
		catch (GLib.Error e) {
			warning (e.message);
			app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
		}

		message (@"Saved secret for $(account.handle)");
	}

	InstanceAccount? secret_to_account (Secret.Retrievable item) {
		InstanceAccount? account = null;
		try {
			var secret = item.retrieve_secret_sync ();
			var contents = secret.get_text ();
			var parser = new Json.Parser ();
			parser.load_from_data (contents, -1);
			account = accounts.create_account (parser.get_root ());
		}
		catch (GLib.Error e) {
			warning (e.message);
		}
		return account;
	}

}
