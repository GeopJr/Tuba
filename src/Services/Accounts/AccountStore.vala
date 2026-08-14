public abstract class Tuba.AccountStore : GLib.Object {

	public Gee.ArrayList<InstanceAccount> saved { get; set; default = new Gee.ArrayList<InstanceAccount> (); }
	public InstanceAccount? active { get; set; default = null; }

	public signal void changed (Gee.ArrayList<InstanceAccount> accounts);
	public signal void switched (InstanceAccount? account);

	public bool ensure_active_account () {
		var has_active = false;
		var account = find_by_uuid (settings.active_account);
		var clear_cache = false;

		if (account == null && !saved.is_empty) {
			account = saved[0];
			clear_cache = true;
		}

		has_active = account != null;
		activate (account, clear_cache);

		if (!has_active)
			app.present_window (true);

		return has_active;
	}

	public virtual void init () throws GLib.Error {
		Mastodon.Account.register (this);

		load ();
		ensure_active_account ();
	}

	public abstract async void update_account_info (InstanceAccount account);
	public abstract void update_account (InstanceAccount account) throws GLib.Error;
	public abstract void load () throws GLib.Error;
	public abstract void save () throws GLib.Error;
	public abstract async void revoke_token_dangerous (InstanceAccount account, bool should_handle_error = true);
	//  public void safe_save () {
	//  	try {
	//  		save ();
	//  	} catch (GLib.Error e) {
	//  		warning (e.message);
	//  		var dlg = app.inform (_("Error"), e.message);
	//  		dlg.present (app.main_window);
	//  	}
	//  }

	public virtual void add (InstanceAccount account) throws GLib.Error {
		debug (@"Adding new account: $(account.handle)");
		saved.add (account);
		changed (saved);
		save ();
		ensure_active_account ();
	}

	public virtual void remove (InstanceAccount account) throws GLib.Error {
		debug (@"Removing account: $(account.handle)");
		account.removed ();
		saved.remove (account);
		changed (saved);
		save ();
		ensure_active_account ();
	}

	public InstanceAccount? find_by_uuid (string uuid) {
		if (!GLib.Uuid.string_is_valid (uuid)) return null;
		var iter = saved.filter (acc => {
			return acc.uuid == uuid;
		});
		iter.next ();

		if (!iter.valid)
			return null;
		else
			return iter.@get ();
	}

	public void activate (InstanceAccount? account, bool clear_cache = false) {
		if (active != null)
			active.deactivated ();

		if (account == null) {
			debug ("Reset active account");
			return;
		} else {
			debug (@"Activating $(account.handle)…");
			if (clear_cache)
				network.clear_cache ();
			settings.active_account = account.uuid;
			this.verify_credentials.begin (account);
		}

		accounts.active = account;
		active.activated ();
		switched (active);
	}

	public async void verify_credentials (InstanceAccount account) {
		try {
			yield account.verify_credentials ();
			if (account.source != null) {
				if (account.source.quote_policy != null && account.source.quote_policy != "") settings.default_quote_policy = account.source.quote_policy;
				if (account.source.language != null && account.source.language != "") settings.default_language = account.source.language;
				if (account.source.privacy != null && account.source.privacy != "") {
					string visibility_id = account.source.privacy.down ();
					if (account.visibility.has_key (visibility_id)) settings.default_post_visibility = visibility_id;
				}
				account.unreviewed_follow_requests = account.source.follow_requests_count;
			}
			account.tuba_verified_credentials = true;
		} catch (Oopsie.HTTP_401 e) {
			warning (@"Couldn't activate account $(account.handle):");
			warning (e.message);
			account.tuba_revoked = true;
			ask_refresh_account_token.begin (account);
		} catch (Error e) {
			warning (@"Couldn't activate account $(account.handle):");
			warning (e.message);
		}
	}

	private async void ask_refresh_account_token (InstanceAccount account) {
		var res = yield app.question (
			// translators: dialog title shown when a user's token has been revoked
			//				and Tuba is asking them if they want to re-login. You
			//				may replace "Reauthenticate" with "Reconnect" or "Re-login"
			{_("Reauthenticate account?"), false},
			// translators: dialog subtitle shown when a user's token has been revoked
			//				and Tuba is asking them if they want to re-login. "password
			//				expired" can be replaced with "credentials expired" or "login
			//				expired". It's not the actual user password, just their token.
			//				The first variable is a string account handle, the second
			//				variable is the app name (Tuba).
			{_("%s's password expired. To continue using %s, you have to login again.").printf (account.handle, Build.NAME), false},
			app.main_window,
			{
				// translators: dialog button shown when a user's token has been revoked
				//				and Tuba is asking them if they want to re-login. Please
				//				use the same verb used in the dialog title "Reauthenticate
				//				account?"
				{ _("Reauthenticate"), Adw.ResponseAppearance.SUGGESTED },
				{ _("Forget Account"), Adw.ResponseAppearance.DESTRUCTIVE }
			},
			null, false
		);

		// handle everything but CANCEL
		if (res == Application.QuestionAnswer.YES) {
			new Dialogs.NewAccount (true, account).present ();
		} else if (res == Application.QuestionAnswer.NO) {
			try {
				this.remove (account);
			} catch (Error e) {
				warning (@"Couldn't remove account $(account.handle): $(e.code) $(e.message)");
			}
		}
	}

	public signal InstanceAccount? create_for_backend (Json.Node node);
	public InstanceAccount create_account (Json.Node node, InstanceAccount.InstanceFeatures? instance_features = null) throws GLib.Error {
		var obj = node.get_object ();
		var backend = obj.get_string_member ("backend");
		var handle = obj.get_string_member ("handle");
		var account = create_for_backend (node);
		if (account == null)
			throw new Oopsie.INTERNAL (@"Account $handle has unknown backend: $backend");

		if (obj.has_member ("api-versions")) {
			var api_versions = obj.get_object_member ("api-versions");
			if (api_versions != null) {
				if (api_versions.has_member ("mastodon")) account.tuba_api_versions.mastodon = (int8) api_versions.get_int_member ("mastodon");
				if (api_versions.has_member ("chuckya")) account.tuba_api_versions.chuckya = (int8) api_versions.get_int_member ("chuckya");
			}
		}

		if (obj.has_member ("instance-features") || instance_features != null) {
			account.tuba_instance_features = instance_features == null ?
				(InstanceAccount.InstanceFeatures) obj.get_int_member ("instance-features")
				: instance_features;

			if (InstanceAccount.InstanceFeatures.ICESHRIMP in account.tuba_instance_features && obj.has_member ("iceshrimp-api-key"))
				account.tuba_iceshrimp_api_key = obj.get_string_member ("iceshrimp-api-key");
		}

		if (obj.has_member ("streaming")) {
			account.tuba_streaming_url = obj.get_string_member ("streaming");
		}

		if (account.uuid == null || !GLib.Uuid.string_is_valid (account.uuid)) account.uuid = GLib.Uuid.string_random ();
		return account;
	}

	// This is a super overcomplicated way and I don't like this.
	// I just want to store an array with functions that return
	// a "string?" value and keep the first non-null one.
	//
	// I figured signals with GSignalAccumulator could be
	// useful here, but Vala doesn't support that either.
	//
	// So here we go. Vala bad. No cookie.
	public abstract class BackendTest : GLib.Object {

		public abstract string? get_backend (Json.Object obj);

	}

	public async void guess_backend (InstanceAccount account) throws GLib.Error {
		account.backend = "Fediverse";
		var req = new RequestV2 ("/.well-known/nodeinfo") { account = account };
		var in_stream = yield req.exec (null);

		Json.Parser parser = yield Network.get_parser_from_inputstream_async (in_stream);
		var node = network.parse_node (parser);
		API.Nodeinfo known_nodeinfo = (API.Nodeinfo) Helper.Entity.from_json (node, typeof (API.Nodeinfo));

		if (known_nodeinfo.links == null || known_nodeinfo.links.size == 0)
			throw new Oopsie.INTERNAL ("Instance does not support nodeinfo");

		bool supports = false;
		foreach (var link in known_nodeinfo.links) {
			if (!link.rel.contains ("://nodeinfo.diaspora.software/ns/schema/2")) continue;
			supports = true;

			if (link.rel.has_suffix ("://nodeinfo.diaspora.software/ns/schema/2.0") && link.href != null && link.href != "") {
				req = new RequestV2 (link.href);
				try {
					in_stream = yield req.exec (null);
					parser = yield Network.get_parser_from_inputstream_async (in_stream);
					node = network.parse_node (parser);
					API.Nodeinfo.V20 nodeinfo2 = (API.Nodeinfo.V20) Helper.Entity.from_json (node, typeof (API.Nodeinfo.V20));
					if (nodeinfo2.software != null && nodeinfo2.software.name != null) {
						account.backend = nodeinfo2.software.name;
						if (nodeinfo2.software.name == "Iceshrimp.NET") account.tuba_instance_features |= InstanceAccount.InstanceFeatures.ICESHRIMP;
						else if (nodeinfo2.software.name == "gotosocial") account.tuba_instance_features |= InstanceAccount.InstanceFeatures.GOTOSOCIAL;
					}
				} catch (Error e) {
					warning (@"Couldn't get Nodeinfo for $(link.rel): $(e.code) $(e.message)");
				}
			}
		}

		if (!supports)
			throw new Oopsie.INTERNAL ("This instance does not support https://nodeinfo.diaspora.software/schema.html");
		debug (@"$(account.instance) is using $(account.backend)");
	}

}
