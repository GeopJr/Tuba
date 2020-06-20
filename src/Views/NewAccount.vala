using Gtk;

public class Tootle.Views.NewAccount : Views.Base {

	private string? instance { get; set; }
	private string? code { get; set; }
	private string scopes = "read%20write%20follow";

	private string? client_id { get; set; }
	private string? client_secret { get; set; }
	private string? access_token { get; set; }
	private string redirect_uri { get; set; default = "urn:ietf:wg:oauth:2.0:oob"; } //TODO: Investigate URI handling for automatic token getting
	private InstanceAccount account;

	private Button next_button;
	private Entry instance_entry;
	private Entry code_entry;
	private Label reset_label;

	private Stack stack;
	private Widget step1;
	private Widget step2;

	public NewAccount (bool allow_closing = true) {
		Object (allow_closing: allow_closing);

		var builder = new Builder.from_resource (@"$(Build.RESOURCES)ui/views/new_account.ui");
		content.pack_start (builder.get_object ("wizard") as Grid);
		state = "content";
		next_button = builder.get_object ("next") as Button;
		reset_label = builder.get_object ("reset") as Label;
		instance_entry = builder.get_object ("instance_entry") as Entry;
		code_entry = builder.get_object ("code_entry") as Entry;

		stack = builder.get_object ("stack") as Stack;
		step1 = builder.get_object ("step1") as Widget;
		step2 = builder.get_object ("step2") as Widget;

		next_button.clicked.connect (on_next_clicked);
		reset_label.activate_link.connect (reset);
		instance_entry.text = "https://mastodon.social/"; //TODO: REMOVE ME
		info ("New account view was requested");
	}

	bool reset () {
		info ("State invalidated");
		instance = code = client_id = client_secret = access_token = null;
		instance_entry.sensitive = true;
		stack.visible_child = step1;
		return true;
	}

	void oopsie (string message) {
		warning (message);
	}

	void on_next_clicked () {
		try {
			step ();
		}
		catch (Oopsie e) {
			oopsie (e.message);
		}
	}

	void step () throws Error {
		if (instance == null)
			setup_instance ();

		if (client_secret == null || client_id == null) {
			register_client ();
			return;
		}

		code = code_entry.text;
		request_token ();
	}

	void setup_instance () throws Error {
		info ("Checking instance URL");

		var str = instance_entry.text
			.replace ("/", "")
			.replace (":", "")
			.replace ("https", "")
			.replace ("http", "");
		instance = "https://"+str;
		instance_entry.text = str;

		if (str.char_count () <= 0 || !("." in instance))
			throw new Oopsie.USER (_("Instance URL is invalid"));
	}

	void register_client () throws Error {
		info ("Registering client");
		instance_entry.sensitive = false;

		account = new InstanceAccount.empty (instance);

		new Request.POST (@"/api/v1/apps")
			.with_param ("client_name", Build.NAME)
			.with_param ("website", Build.WEBSITE)
			.with_param ("scopes", scopes)
			.with_param ("redirect_uris", redirect_uri)
			.with_account (account)
			.then ((sess, msg) => {
				var root = network.parse (msg);
				client_id = root.get_string_member ("client_id");
				client_secret = root.get_string_member ("client_secret");
				info ("OK: instance registered client");
				stack.visible_child = step2;

				open_confirmation_page ();
			})
			.on_error ((status, reason) => {
				oopsie (reason);
				instance_entry.sensitive = true;
			})
			.exec ();
	}

	void open_confirmation_page () {
		info ("Opening permission request page");

		var pars = @"scope=$scopes&response_type=code&redirect_uri=$redirect_uri&client_id=$client_id";
		var url = @"$instance/oauth/authorize?$pars";
		Desktop.open_uri (url);
	}

	void request_token () throws Error {
		if (code.char_count () <= 10)
			throw new Oopsie.USER (_("Please paste a valid authorization code"));

		info ("Requesting access token");
        new Request.POST (@"/oauth/token")
        	.with_account (account)
        	.with_param ("client_id", client_id)
        	.with_param ("client_secret", client_secret)
        	.with_param ("redirect_uri", redirect_uri)
        	.with_param ("grant_type", "authorization_code")
        	.with_param ("code", code)
        	.then ((sess, msg) => {
		    	var root = network.parse (msg);
		    	access_token = root.get_string_member ("access_token");
		    	account.access_token = access_token;
		    	account.id = "";
		    	info ("OK: received access token");
		    	request_profile ();
        	})
        	.on_error ((code, reason) => oopsie (reason))
        	.exec ();
	}

	void request_profile () throws Error {
		info ("Testing received access token");
		new Request.GET ("/api/v1/accounts/verify_credentials")
			.with_account (account)
			.then ((sess, msg) => {
				var node = network.parse_node (msg);
				var account = API.Account.from (node);
				info ("OK: received user profile");
				save (account);
			})
			.on_error ((status, reason) => {
				reset ();
				oopsie (reason);
			})
			.exec ();
	}

	void save (API.Account profile) {
		info ("Account validated. Saving...");
		account.patch (profile);
		account.instance = instance;
		account.client_id = client_id;
		account.client_secret = client_secret;
		account.access_token = access_token;
		accounts.add (account);

		destroy ();
	}

}
