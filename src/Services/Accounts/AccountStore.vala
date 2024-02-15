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

	public abstract void load () throws GLib.Error;
	public abstract void save () throws GLib.Error;
	public void safe_save () {
		try {
			save ();
		}
		catch (GLib.Error e) {
			warning (e.message);
			var dlg = app.inform (_("Error"), e.message);
			dlg.present ();
		}
	}

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
			account.verify_credentials.begin ((obj, res) => {
				try {
					account.verify_credentials.end (res);
					account.error = null;
					settings.active_account = account.uuid;
					if (account.source != null && account.source.language != null && account.source.language != "")
						settings.default_language = account.source.language;
				}
				catch (Error e) {
					warning (@"Couldn't activate account $(account.handle):");
					warning (e.message);
					account.error = e;
				}
			});
		}

		accounts.active = account;
		active.activated ();
		switched (active);
	}

	[Signal (detailed = true)]
	public signal InstanceAccount? create_for_backend (Json.Node node);

	public InstanceAccount create_account (Json.Node node) throws GLib.Error {
		var obj = node.get_object ();
		var backend = obj.get_string_member ("backend");
		var handle = obj.get_string_member ("handle");
		var account = create_for_backend[backend] (node);
		if (account == null)
			throw new Oopsie.INTERNAL (@"Account $handle has unknown backend: $backend");

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

	public Gee.ArrayList<BackendTest> backend_tests = new Gee.ArrayList<BackendTest> ();

	public async void guess_backend (InstanceAccount account) throws GLib.Error {
		var req = new Request.GET ("/api/v1/instance")
			.with_account (account);
		yield req.await ();

		var parser = Network.get_parser_from_inputstream (req.response_body);
		var root = network.parse (parser);

		string? backend = null;
		backend_tests.foreach (test => {
			backend = test.get_backend (root);
			return true;
		});

		if (backend == null)
			throw new Oopsie.INTERNAL ("This instance is unsupported.");
		else {
			account.backend = backend;
			debug (@"$(account.instance) is using $(account.backend)");
		}
	}

}
