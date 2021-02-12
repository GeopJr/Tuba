using Gtk;

[GtkTemplate (ui = "/com/github/bleakgrey/tootle/ui/dialogs/new_account.ui")]
public class Tootle.Dialogs.NewAccount: Hdy.Window {

	const string scopes = "read%20write%20follow";

	protected bool is_working { get; set; default = false; }
	protected string? redirect_uri { get; set; }
	protected bool use_auto_auth { get; set; default = true; }
	protected InstanceAccount account { get; set; default = new InstanceAccount.empty (""); }

	[GtkChild]
	Button back_button;
	[GtkChild]
	Button next_button;

	[GtkChild]
	Stack stack;
	[GtkChild]
	Box instance_step;
	[GtkChild]
	Box code_step;
	[GtkChild]
	Box done_step;

	[GtkChild]
	Entry instance_entry;
	[GtkChild]
	Entry code_entry;
	[GtkChild]
	Label code_label;
	[GtkChild]
	Label hello_label;

	public NewAccount () {
		Object (transient_for: window);
		StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), app.css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
		reset ();
		present ();
		new_account_window = this;

		bind_property ("use-auto-auth", code_label, "visible", BindingFlags.SYNC_CREATE);
	}

	public override bool delete_event (Gdk.EventAny event) {
		new_account_window = null;
		return app.on_window_closed ();
	}

	string setup_redirect_uri () {
		try {
			if (!use_auto_auth)
				throw new Oopsie.INTERNAL ("Using manual auth method");

			GLib.Process.spawn_command_line_sync (@"xdg-mime default $(Build.DOMAIN).desktop x-scheme-handler/tootle");

			message ("Successfully associated MIME type for automatic authorization");
			return "tootle://auth_code";
		}
		catch (Error e) {
			warning (e.message);
			use_auto_auth = false;
			return "urn:ietf:wg:oauth:2.0:oob";
		}
	}

	[GtkCallback]
	bool on_activate_code_label_link (string uri) {
		use_auto_auth = false;
		reset ();
		return true;
	}

	void reset () {
		message ("Reset state");
		account = new InstanceAccount.empty (account.instance);
		stack.visible_child = instance_step;
		invalidate ();
	}

	void invalidate () {
		next_button.sensitive = !is_working;
		next_button.label = stack.visible_child == done_step ? _("Close") : _("Next");
		back_button.label = stack.visible_child == done_step ? _("Add Another") : _("Back");
		back_button.visible = stack.visible_child != instance_step;
	}

	void oopsie (string title, string msg = "") {
		warning (@"$title   $msg");
		app.inform (Gtk.MessageType.ERROR, title, msg, this);
	}

	async void step () throws Error {
		if (stack.visible_child == done_step) {
			app.present_window ();
			destroy ();
			return;
		}

		if (stack.visible_child == instance_step) {
			setup_instance ();
			yield accounts.guess_backend (account);
		}

		if (account.client_secret == null || account.client_id == null) {
			yield register_client ();
			return;
		}

		yield request_token ();
	}

	void setup_instance () throws Error {
		message ("Checking instance");

		var str = instance_entry.text
			.replace ("/", "")
			.replace (":", "")
			.replace ("https", "")
			.replace ("http", "");
		account.instance = "https://"+str;
		instance_entry.text = str;

		if (str.char_count () <= 0 || !("." in account.instance))
			throw new Oopsie.USER (_("Please enter a valid instance URL"));
	}

	async void register_client () throws Error {
		message ("Registering client");

		var msg = new Request.POST (@"/api/v1/apps")
			.with_account (account)
			.with_param ("client_name", Build.NAME)
			.with_param ("website", Build.WEBSITE)
			.with_param ("scopes", scopes)
			.with_param ("redirect_uris", redirect_uri = setup_redirect_uri ());
		yield msg.await ();

		var root = network.parse (msg);
		account.client_id = root.get_string_member ("client_id");
		account.client_secret = root.get_string_member ("client_secret");
		message ("OK: Instance registered client");

		stack.visible_child = code_step;
		open_confirmation_page ();
	}

	void open_confirmation_page () {
		message ("Opening permission request page");

		var pars = @"scope=$scopes&response_type=code&redirect_uri=$redirect_uri&client_id=$(account.client_id)";
		var url = @"$(account.instance)/oauth/authorize?$pars";
		Desktop.open_uri (url);
	}

	async void request_token () throws Error {
		if (code_entry.text.char_count () <= 1)
			throw new Oopsie.USER (_("Please enter a valid authorization code"));

		message ("Requesting access token");
		var token_req = new Request.POST (@"/oauth/token")
			.with_account (account)
			.with_param ("client_id", account.client_id)
			.with_param ("client_secret", account.client_secret)
			.with_param ("redirect_uri", redirect_uri)
			.with_param ("grant_type", "authorization_code")
			.with_param ("code", code_entry.text);
		yield token_req.await ();

		var root = network.parse (token_req);
		account.access_token = root.get_string_member ("access_token");

		if (account.access_token == null)
			throw new Oopsie.INSTANCE (_("Instance failed to authorize the access token"));

		yield account.verify_credentials ();

		account = accounts.create_account (account.to_json ());

		message ("Saving account");
		accounts.add (account);

		hello_label.label = _("Hello, %s!").printf (account.handle);
		stack.visible_child = done_step;

		message ("Switching to account");
		accounts.activate (account);
	}

	public void redirect (string uri) {
		present ();
		message (@"Received uri: $uri");

		var query = new Soup.URI (uri).get_query ();
		var split = query.split ("=");
		var code = split[1];

		code_entry.text = code;
		is_working = false;
		on_next_clicked ();
	}

	[GtkCallback]
	void on_next_clicked () {
		if (is_working) return;

		is_working = true;
		invalidate ();
		step.begin ((obj, res) => {
			try {
				step.end (res);
			}
			catch (Oopsie.INSTANCE e) {
				oopsie (_("Server returned an error"), e.message);
			}
			catch (Error e) {
				oopsie (e.message);
			}
			is_working = false;
			invalidate ();
		});
	}

	[GtkCallback]
	void on_back_clicked () {
		reset ();
	}

}

