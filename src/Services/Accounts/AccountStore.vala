using Gee;

public abstract class Tooth.AccountStore : GLib.Object {

	public ArrayList<InstanceAccount> saved { get; set; default = new ArrayList<InstanceAccount> (); }
	public InstanceAccount? active { get; set; default = null; }

	public signal void changed (ArrayList<InstanceAccount> accounts);
	public signal void switched (InstanceAccount? account);

	public bool ensure_active_account () {
		var has_active = false;
		var account = find_by_handle (settings.active_account);

		if (account == null && !saved.is_empty) {
			account = saved[0];
		}

		has_active = account != null;
		activate (account);

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
			app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
		}
	}

	public virtual void add (InstanceAccount account) throws GLib.Error {
		message (@"Adding new account: $(account.handle)");
		saved.add (account);
		changed (saved);
		save ();
		ensure_active_account ();
	}

	public virtual void remove (InstanceAccount account) throws GLib.Error {
		message (@"Removing account: $(account.handle)");
		account.removed ();
		saved.remove (account);
		changed (saved);
		save ();
		ensure_active_account ();
	}

	public InstanceAccount? find_by_handle (string handle) {
		var iter = saved.filter (acc => {
			return acc.handle == handle;
		});
		iter.next ();

		if (!iter.valid)
			return null;
		else
			return iter.@get ();
	}

	public void activate (InstanceAccount? account) {
		if (active != null)
			active.deactivated ();

		if (account == null) {
			message ("Reset active account");
			return;
		}
		else {
			message (@"Activating $(account.handle)...");
			account.verify_credentials.begin ((obj, res) => {
				try {
					account.verify_credentials.end (res);
					account.error = null;
					settings.active_account = account.handle;
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

		var root = network.parse (req);

		string? backend = null;
		backend_tests.foreach (test => {
			backend = test.get_backend (root);
			return true;
		});

		if (backend == null)
			throw new Oopsie.INTERNAL ("This instance is unsupported.");
		else {
			account.backend = backend;
			message (@"$(account.instance) is using $(account.backend)");
		}
	}

}
