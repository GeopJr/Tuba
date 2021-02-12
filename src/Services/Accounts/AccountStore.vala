using Gee;

public abstract class Tootle.AccountStore : GLib.Object {

	public ArrayList<InstanceAccount> saved { get; set; default = new ArrayList<InstanceAccount> (); }
	public InstanceAccount? active { get; set; default = null; }

	// TODO: Make settings.current_account a string
	public bool ensure_active_account () {
		var has_active = false;

		if (!saved.is_empty) {
			if (settings.current_account > saved.size || settings.current_account <= 0)
				settings.current_account = 0;

			var last_account = saved[settings.current_account];
			if (active != last_account) {
				activate (last_account);
				has_active = true;
			}
		}

		if (!has_active)
			app.present_window ();

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
		save ();
		account.subscribe ();
		ensure_active_account ();
	}

	public virtual void remove (InstanceAccount account) throws GLib.Error {
		message (@"Removing account: $(account.handle)");
		account.unsubscribe ();
		saved.remove (account);
		saved.notify_property ("size");
		save ();

		var id = settings.current_account - 1;
		if (saved.size < 1)
			active = null;
		else {
			if (id > saved.size - 1)
				id = saved.size - 1;
			else if (id < saved.size - 1)
				id = 0;
		}
		settings.current_account = id;

		ensure_active_account ();
	}

	public void activate (InstanceAccount account) {
		message (@"Activating $(account.handle)...");
		account.verify_credentials.begin ((obj, res) => {
			try {
				account.verify_credentials.end (res);
				account.error = null;
			}
			catch (Error e) {
				warning (@"Couldn't activate account $(account.handle):");
				warning (e.message);
				account.error = e;
			}
		});

		accounts.active = account;
		settings.current_account = accounts.saved.index_of (account);
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
