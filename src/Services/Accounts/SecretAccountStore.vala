public class Tuba.SecretAccountStore : AccountStore {

	const string VERSION = "1";

	Secret.Schema schema;
	GLib.HashTable<string,Secret.SchemaAttributeType> schema_attributes;

	public override void init () throws GLib.Error {
		debug (@"Using libsecret v$(Secret.MAJOR_VERSION).$(Secret.MINOR_VERSION).$(Secret.MICRO_VERSION)");

		schema_attributes = new GLib.HashTable<string,Secret.SchemaAttributeType> (str_hash, str_equal);
		schema_attributes["login"] = Secret.SchemaAttributeType.STRING;
		schema_attributes["version"] = Secret.SchemaAttributeType.STRING;
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

		List<Secret.Retrievable> secrets = new List<Secret.Retrievable> ();
		try {
			secrets = Secret.password_searchv_sync (
				schema,
				attrs,
				Secret.SearchFlags.ALL | Secret.SearchFlags.UNLOCK,
				null
			);
		} catch (GLib.Error e) {
			string wiki_page = "https://github.com/GeopJr/Tuba/wiki/keyring-issues";

			// Let's leave this untranslated for now
			string help_msg = "If you didn’t manually cancel it, try creating a password keyring named \"login\" using Passwords and Keys (seahorse) or KWalletManager"; // vala-lint=line-length

			if (e.message == "org.freedesktop.DBus.Error.ServiceUnknown") {
				wiki_page = "https://github.com/GeopJr/Tuba/wiki/libsecret-issues";
				help_msg = @"$(e.message), $(Build.NAME) might be missing some permissions";
			}

			critical (@"Error while searching for items in the secret service: $(e.message)");
			warning (@"$help_msg\nread more: $wiki_page");

			new Dialogs.NewAccount ();
			app.question.begin (
				{"Error while searching for user accounts", false},
				{@"$help_msg.", false},
				app.add_account_window,
				{ {"Read More", Adw.ResponseAppearance.SUGGESTED }, { "Close", Adw.ResponseAppearance.DEFAULT } },
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) Host.open_url (wiki_page);
					Process.exit (1);
				}
			);
		}

		secrets.foreach (item => {
			// TODO: remove uuid fallback
			bool force_save = false;
			var account = secret_to_account (item, out force_save);
			if (account != null && account.id != "") {
				new Request.GET (@"/api/v1/accounts/$(account.id)")
					.with_account (account)
					.then ((in_stream) => {
						var parser = Network.get_parser_from_inputstream (in_stream);
						var node = network.parse_node (parser);
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

				// TODO: remove uuid fallback
				if (force_save) safe_save ();
			}
		});
		changed (saved);

		debug (@"Loaded $(saved.size) accounts");
	}

	public override void save () throws GLib.Error {
		saved.foreach (account => {
			account_to_secret (account);
			return true;
		});
		debug (@"Saved $(saved.size) accounts");
	}

	public override void remove (InstanceAccount account) throws GLib.Error {
		base.remove (account);

		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["version"] = VERSION;
		attrs["login"] = account.handle;

		Secret.password_clearv.begin (
			schema,
			attrs,
			null,
			(obj, async_res) => {
				try {
					Secret.password_clearv.end (async_res);
				}
				catch (GLib.Error e) {
					warning (e.message);
					var dlg = app.inform (_("Error"), e.message);
					dlg.present (app.main_window);
				}
			}
		);
	}

	void account_to_secret (InstanceAccount account) {
		var attrs = new GLib.HashTable<string,string> (str_hash, str_equal);
		attrs["login"] = account.handle;
		attrs["version"] = VERSION;

		var generator = new Json.Generator ();

		// Save only what we need
		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("id");
		builder.add_string_value (account.id);

		builder.set_member_name ("username");
		builder.add_string_value (account.username);

		builder.set_member_name ("display-name");
		builder.add_string_value (account.display_name);

		builder.set_member_name ("acct");
		builder.add_string_value (account.acct);

		builder.set_member_name ("header");
		builder.add_string_value (account.header);

		builder.set_member_name ("avatar");
		builder.add_string_value (account.avatar);

		builder.set_member_name ("url");
		builder.add_string_value (account.url);

		builder.set_member_name ("instance");
		builder.add_string_value (account.instance);

		builder.set_member_name ("client-id");
		builder.add_string_value (account.client_id);

		builder.set_member_name ("client-secret");
		builder.add_string_value (account.client_secret);

		builder.set_member_name ("access-token");
		builder.add_string_value (account.access_token);

		builder.set_member_name ("handle");
		builder.add_string_value (account.handle);

		builder.set_member_name ("backend");
		builder.add_string_value (account.backend);

		builder.set_member_name ("uuid");
		builder.add_string_value (account.uuid);

		// If display name has emojis it's
		// better to save and load them
		// so users don't see their shortcode
		// while verify_credentials is running
		builder.set_member_name ("emojis");
		builder.begin_array ();
		if (account.emojis?.size > 0) {
			foreach (var emoji in account.emojis) {
					builder.begin_object ();

					builder.set_member_name ("shortcode");
					builder.add_string_value (emoji.shortcode);

					builder.set_member_name ("url");
					builder.add_string_value (emoji.url);

					builder.end_object ();
			}
		}
		builder.end_array ();

		builder.end_object ();
		generator.set_root (builder.get_root ());
		var secret = generator.to_data (null);
		// translators: The variable is the backend like "Mastodon"
		var label = _("%s Account").printf (account.backend);

		Secret.password_storev.begin (
			schema,
			attrs,
			Secret.COLLECTION_DEFAULT,
			label,
			secret,
			null,
			(obj, async_res) => {
				try {
					Secret.password_store.end (async_res);
					debug (@"Saved secret for $(account.handle)");
				}
				catch (GLib.Error e) {
					warning (e.message);
					var dlg = app.inform (_("Error"), e.message);
					dlg.present (app.main_window);
				}
			}
		);
	}

	InstanceAccount? secret_to_account (Secret.Retrievable item, out bool force_save) {
		InstanceAccount? account = null;

		// TODO: remove uuid fallback
		force_save = false;
		try {
			var secret = item.retrieve_secret_sync ();
			var contents = secret.get_text ();
			var parser = new Json.Parser ();
			parser.load_from_data (contents, -1);

			var root = parser.get_root ();
			var root_obj = root.get_object ();

			// HACK: Partial makeshift secret validation
			// see #742 #701 #114
			if (
				!root_obj.has_member ("backend")
				|| !root_obj.has_member ("acct")
				|| !root_obj.has_member ("id")
				|| !root_obj.has_member ("client-secret")
				|| !root_obj.has_member ("client-id")
				|| !root_obj.has_member ("access-token")
			) return null;

			// TODO: remove uuid fallback
			bool had_uuid = root_obj.has_member ("uuid");
			account = accounts.create_account (root);

			// TODO: remove uuid fallback
			force_save = !had_uuid && account.uuid != null;
		} catch (GLib.Error e) {
			warning (e.message);
		}
		return account;
	}

}
