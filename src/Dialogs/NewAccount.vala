using Gtk;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/new_account.ui")]
public class Tuba.Dialogs.NewAccount: Adw.Window {
	const string AUTO_AUTH_DESCRIPTION = _("Allow access to your account in the browser.");
	const string CODE_AUTH_DESCRIPTION = _("Copy the authorization code from the browser and paste it below.");

	const string SCOPES = "read write follow";

	protected bool is_working { get; set; default = false; }
	protected string? redirect_uri { get; set; }
	protected bool use_auto_auth { get; set; default = true; }
	protected InstanceAccount account { get; set; default = new InstanceAccount.empty (""); }

	[GtkChild] unowned Adw.Leaflet deck;
	[GtkChild] unowned Box instance_step;
	[GtkChild] unowned Box code_step;
	[GtkChild] unowned Box done_step;

	[GtkChild] unowned Adw.EntryRow instance_entry;
	[GtkChild] unowned Label instance_entry_error;

	[GtkChild] unowned Adw.EntryRow code_entry;
	[GtkChild] unowned Label code_entry_error;

	[GtkChild] unowned Adw.StatusPage auth_page;
	[GtkChild] unowned Adw.StatusPage done_page;

	[GtkChild] unowned Gtk.Label manual_auth_label;

	public NewAccount () {
		Object (transient_for: app.main_window);
		app.add_account_window = this;
		app.add_window (this);

		bind_property ("use-auto-auth", auth_page, "description", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (src.get_boolean () ? AUTO_AUTH_DESCRIPTION : CODE_AUTH_DESCRIPTION);
			return true;
		});

		manual_auth_label.activate_link.connect (on_manual_auth);

		reset ();
		present ();
	}

	public bool on_manual_auth (string url) {
		if (url == "manual_auth") {
			use_auto_auth = false;
			register_client.begin ();
		} else {
			warning (@"Expected \"manual_auth\", instead got \"$(url)\"");
		}

		return true;
	}

	public override bool close_request () {
		warning ("Close Request");
		app.add_account_window = null;
		return base.close_request ();
	}

	string setup_redirect_uri () {
		try {
			if (!use_auto_auth)
				throw new Oopsie.INTERNAL ("Using manual auth method");

			//  GLib.Process.spawn_command_line_sync (@"xdg-mime default $(Build.DOMAIN).desktop x-scheme-handler/tuba");

			//  message ("Successfully associated MIME type for automatic authorization");
			return "tuba://auth_code";
		}
		catch (Error e) {
			warning (e.message);
			use_auto_auth = false;
			return "urn:ietf:wg:oauth:2.0:oob";
		}
	}

	void reset () {
		message ("Reset state");
		clear_errors ();
		use_auto_auth = true;
		account = new InstanceAccount.empty (account.instance);
		deck.visible_child = instance_step;
	}

	void oopsie (string title, string msg = "") {
		warning (@"$title   $msg.");
		var dlg = app.inform (title, msg, this);
		dlg.present ();
	}

	async void step () throws Error {
		if (deck.visible_child == instance_step) {
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
		message ("Checking instance URL");

		var str = instance_entry.text
			.replace ("/", "")
			.replace (":", "")
			.replace ("https", "")
			.replace ("http", "");
		account.instance = @"https://$str";
		instance_entry.text = str;

		if (str.char_count () <= 0 || !("." in account.instance))
			throw new Oopsie.USER (_("Please enter a valid instance URL"));
	}

	async void register_client () throws Error {
		message ("Registering client");

		var msg = new Request.POST ("/api/v1/apps")
			.with_account (account)
			.with_form_data ("client_name", Build.NAME)
			.with_form_data ("redirect_uris", redirect_uri = setup_redirect_uri ())
			.with_form_data ("scopes", SCOPES)
			.with_form_data ("website", Build.WEBSITE);
		yield msg.await ();

		var parser = Network.get_parser_from_inputstream (msg.response_body);
		var root = network.parse (parser);
		account.client_id = root.get_string_member ("client_id");
		account.client_secret = root.get_string_member ("client_secret");
		message ("OK: Instance registered client");

		deck.visible_child = code_step;
		open_confirmation_page ();
	}

	void open_confirmation_page () {
		message ("Opening permission request page");

		var pars = @"scope=$SCOPES&response_type=code&redirect_uri=$redirect_uri&client_id=$(account.client_id)";
		var url = @"$(account.instance)/oauth/authorize?$pars";
		Host.open_uri (url);
	}

	async void request_token () throws Error {
		if (code_entry.text.char_count () <= 10)
			throw new Oopsie.USER (_("Please enter a valid authorization code"));

		message ("Requesting access token");
		var token_req = new Request.POST ("/oauth/token")
			.with_account (account)
			.with_form_data ("client_id", account.client_id)
			.with_form_data ("client_secret", account.client_secret)
			.with_form_data ("redirect_uri", redirect_uri)
			.with_form_data ("grant_type", "authorization_code")
			.with_form_data ("code", code_entry.text);
		yield token_req.await ();

		var parser = Network.get_parser_from_inputstream (token_req.response_body);
		var root = network.parse (parser);
		account.access_token = root.get_string_member ("access_token");

		if (account.access_token == null)
			throw new Oopsie.INSTANCE (_("Instance failed to authorize the access token"));

		yield account.verify_credentials ();

		account = accounts.create_account (account.to_json ());

		message ("Saving account");
		accounts.add (account);

		done_page.title = _("Hello, %s!").printf (account.display_name);
		deck.visible_child = done_step;

		message ("Switching to account");
		accounts.activate (account);
	}

	public void redirect (string t_uri) {
		present ();
		message (@"Received uri: $t_uri");

		string code_from_params = "";
		try {
			var uri = Uri.parse (t_uri, UriFlags.NONE);
			var uri_params = Uri.parse_params (uri.get_query ());
			if (uri_params.contains ("code"))
				code_from_params = uri_params.get ("code");
		} catch (GLib.UriError e) {
			warning (e.message);
			return;
		}

		code_entry.text = code_from_params;
		is_working = false;
		on_next_clicked ();
	}

	public void mark_errors (string error_message) {
		instance_entry.add_css_class ("error");
		instance_entry_error.label = error_message;

		code_entry.add_css_class ("error");
		code_entry_error.label = error_message;
	}

	[GtkCallback]
	public void clear_errors () {
		instance_entry.remove_css_class ("error");
		instance_entry_error.label = "";

		code_entry.remove_css_class ("error");
		code_entry_error.label = "";
	}

	[GtkCallback]
	void on_next_clicked () {
		clear_errors ();
		if (is_working) return;

		is_working = true;
		step.begin ((obj, res) => {
			try {
				step.end (res);
				clear_errors ();
			}
			catch (Oopsie.INSTANCE e) {
				oopsie (_("Server returned an error"), e.message);
				mark_errors (e.message);
			}
			catch (Error e) {
				oopsie (e.message);
				mark_errors (e.message);
			}
			is_working = false;
		});
	}

	[GtkCallback]
	void on_done_clicked () {
		app.present_window ();
		app.add_account_window = null;
		destroy ();
	}

	[GtkCallback]
	void on_back_clicked () {
		reset ();
	}

	[GtkCallback]
	void on_visible_child_notify () {
		if (!deck.child_transition_running && deck.visible_child == instance_step)
			reset ();

		deck.can_navigate_back = deck.visible_child != done_step;
	}
}
