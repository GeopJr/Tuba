[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/new_account.ui")]
public class Tuba.Dialogs.NewAccount: Adw.Window {
	const string AUTO_AUTH_DESCRIPTION = _("Allow access to your account in the browser.");
	const string CODE_AUTH_DESCRIPTION = _("Copy the authorization code from the browser and paste it below.");

	const string SCOPES = "read write follow";
	const string ADMIN_SCOPES = "admin:read admin:write admin:read:reports admin:write:reports admin:read:ip_blocks admin:write:ip_blocks admin:read:domain_blocks admin:write:domain_blocks admin:read:domain_allows admin:write:domain_allows admin:read:email_domain_blocks admin:write:email_domain_blocks admin:read:canonical_email_blocks admin:write:canonical_email_blocks";

	#if WINDOWS || DARWIN
		const bool SHOULD_AUTO_AUTH = false;
	#else
		const bool SHOULD_AUTO_AUTH = true;
	#endif

	protected bool is_working { get; set; default = false; }
	protected string? redirect_uri { get; set; }
	protected bool use_auto_auth { get; set; default = SHOULD_AUTO_AUTH; }
	protected InstanceAccount account { get; set; default = new InstanceAccount.empty (""); }
	protected bool can_access_settings { get; set; default=false; }
	protected bool admin_mode { get; set; default=false; }

	[GtkChild] unowned Adw.ToastOverlay toast_overlay;
	[GtkChild] unowned Adw.NavigationView deck;
	[GtkChild] unowned Adw.NavigationPage instance_step;
	[GtkChild] unowned Adw.NavigationPage code_step;
	[GtkChild] unowned Adw.NavigationPage done_step;

	[GtkChild] unowned Adw.EntryRow instance_entry;
	[GtkChild] unowned Gtk.Label instance_entry_error;

	[GtkChild] unowned Adw.EntryRow code_entry;
	[GtkChild] unowned Gtk.Label code_entry_error;

	[GtkChild] unowned Adw.StatusPage auth_page;
	[GtkChild] unowned Widgets.EmojiLabel done_page_emoji_label;

	[GtkChild] unowned Gtk.Label manual_auth_label;

	static construct {
		typeof (Widgets.EmojiLabel).ensure ();
	}

	public string get_full_scopes () {
		string scopes = SCOPES;
		if (this.admin_mode) scopes = @"$scopes $ADMIN_SCOPES";
		if (account != null && (InstanceAccount.InstanceFeatures.ICESHRIMP in account.tuba_instance_features))
			scopes = @"$scopes iceshrimp";

		return scopes;
	}

	public NewAccount (bool can_access_settings = false) {
		Object (transient_for: app.main_window);
		this.can_access_settings = can_access_settings;
		app.add_account_window = this;
		app.add_window (this);

		bind_property ("use-auto-auth", auth_page, "description", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			target.set_string (src.get_boolean () ? AUTO_AUTH_DESCRIPTION : CODE_AUTH_DESCRIPTION);
			return true;
		});

		if (!can_access_settings) {
			app.toast.connect (add_toast);
		} else {
			add_binding_action (Gdk.Key.Escape, 0, "window.close", null);
		}

		manual_auth_label.activate_link.connect (on_manual_auth);

		reset ();
		present ();
		instance_entry.grab_focus ();
	}

	private void add_toast (string content, uint timeout = 0) {
		toast_overlay.add_toast (new Adw.Toast (content) {
			timeout = timeout
		});
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

			return "tuba://auth_code";
		} catch (Error e) {
			warning (e.message);
			use_auto_auth = false;
			return "urn:ietf:wg:oauth:2.0:oob";
		}
	}

	void reset () {
		debug ("Reset state");
		clear_errors ();
		use_auto_auth = SHOULD_AUTO_AUTH;
		account = new InstanceAccount.empty (account.instance);
		deck.pop_to_page (instance_step);
	}

	void oopsie (string title, string msg = "") {
		warning (@"$title   $msg.");
		var dlg = app.inform (title, msg);
		dlg.present (this);
	}

	async void step () throws Error {
		if (deck.visible_page == instance_step) {
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
		bool skip_strict_validation = GLib.Environment.get_variable ("TUBA_SKIP_STRICT_VALIDATION") == "1";
		debug ("Checking instance URL (strict: %s)", skip_strict_validation.to_string ());

		string final_string = instance_entry.text;
		if (!final_string.contains ("://")) final_string = @"https://$final_string";

		string final_string_no_scheme = final_string;
		try {
			GLib.Uri instance_uri = GLib.Uri.parse (final_string, GLib.UriFlags.NONE);
			string scheme = instance_uri.get_scheme ();
			string host = instance_uri.get_host ();
			int port = instance_uri.get_port ();
			string? userinfo = instance_uri.get_userinfo ();

			if (!skip_strict_validation) {
				scheme = "https";
				port = -1;
				userinfo = null;

				if (!host.contains (".")) {
					throw new Error.literal (-1, 1, @"Host '$host' is missing a dot");
				}
			}

			final_string_no_scheme = GLib.Uri.build (
				instance_uri.get_flags (),
				"",
				userinfo,
				host,
				port,
				"",
				null,
				null
			).to_string ().substring (3);
			final_string = @"$scheme://$final_string_no_scheme";
		} catch (Error e) {
			warning ("Couldn't parse instance URI: %s", e.message);
			throw new Oopsie.USER (_("Please enter a valid instance URL"));
		}

		account.instance = final_string;
		instance_entry.text = final_string_no_scheme;
	}

	async void register_client () throws Error {
		debug ("Registering client");

		var msg = new Request.POST ("/api/v1/apps")
			.with_account (account)
			.with_form_data ("client_name", Build.NAME)
			.with_form_data ("redirect_uris", redirect_uri = setup_redirect_uri ())
			.with_form_data ("scopes", get_full_scopes ())
			.with_form_data ("website", Build.WEBSITE);
		yield msg.await ();

		var parser = Network.get_parser_from_inputstream (msg.response_body);
		var root = network.parse (parser);

		if (root.get_string_member ("name") != Build.NAME)
			throw new Oopsie.INSTANCE ("Misconfigured Instance");

		account.client_id = root.get_string_member ("client_id");
		account.client_secret = root.get_string_member ("client_secret");
		debug ("OK: Instance registered client");

		if (deck.visible_page != code_step) {
			deck.push (code_step);
		}
		open_confirmation_page ();
	}

	void open_confirmation_page () {
		debug ("Opening permission request page");

		var esc_scopes = Uri.escape_string (get_full_scopes ());
		var esc_redirect = Uri.escape_string (redirect_uri);
		var pars = @"scope=$esc_scopes&response_type=code&redirect_uri=$esc_redirect&client_id=$(Uri.escape_string (account.client_id))";
		var url = @"$(account.instance)/oauth/authorize?$pars";
		Utils.Host.open_url.begin (url);
	}

	async void request_token () throws Error {
		if (code_entry.text.char_count () <= 10)
			throw new Oopsie.USER (_("Please enter a valid authorization code"));

		debug ("Requesting access token");
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

		account.admin_mode = this.admin_mode;
		account = accounts.create_account (account.to_json ());

		debug ("Saving account");
		accounts.add (account);

		done_page_emoji_label.instance_emojis = account.emojis_map;
		done_page_emoji_label.content = _("Hello, %s!").printf (account.display_name);
		deck.push (done_step);

		debug ("Switching to account");
		accounts.activate (account, true);
	}

	public void redirect (Uri uri) {
		present ();
		debug (@"Received uri: $uri");

		string code_from_params = "";
		try {
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

	class SettingsDialog : Adw.Dialog {
		public signal void admin_changed (bool new_admin_val);

		Adw.EntryRow proxy_entry;
		Adw.SwitchRow admin_row;
		Gtk.Button apply_button;
		construct {
			this.title = _("Settings");
			this.content_width = 460;
			this.content_height = 220;

			var cancel_button = new Gtk.Button.with_label (_("Cancel"));
			cancel_button.clicked.connect (on_cancel);

			apply_button = new Gtk.Button.with_label (_("Apply")) {
				css_classes = {"suggested-action"},
				sensitive =	false
			};
			apply_button.clicked.connect (on_apply);

			var page = new Adw.PreferencesPage () {
				valign = Gtk.Align.CENTER
			};
			var headerbar = new Adw.HeaderBar () {
				show_end_title_buttons = false,
				show_start_title_buttons = false
			};

			headerbar.pack_start (cancel_button);
			headerbar.pack_end (apply_button);

			var toolbar_view = new Adw.ToolbarView () {
				content = page
			};
			toolbar_view.add_top_bar (headerbar);

			var group = new Adw.PreferencesGroup ();
			proxy_entry = new Adw.EntryRow () {
				title = _("Proxy"),
				visible = false,
				input_purpose = Gtk.InputPurpose.URL,
				show_apply_button = false
			};
			group.add (proxy_entry);

			admin_row = new Adw.SwitchRow () {
				// translators: Switch title in the new account window
				title = _("Admin Mode"),
				// translators: Switch description in the new account window
				subtitle = _("Enables the Admin Dashboard and requests the needed permissions to use the Admin API")
			};
			group.add (admin_row);
			page.add (group);

			this.child = toolbar_view;
		}

		bool original_admin_val = false;
		public SettingsDialog (bool can_access_settings = true, string proxy_val = "", bool admin_val = false) {
			if (!can_access_settings) {
				proxy_entry.visible = true;
				proxy_entry.text = proxy_val;
			}
			original_admin_val = admin_val;
			admin_row.active = admin_val;

			admin_row.notify["active"].connect (modified);
			proxy_entry.changed.connect (modified);
		}

		void modified () {
			apply_button.sensitive = admin_row.active != original_admin_val || settings.proxy != proxy_entry.text;
		}

		void on_cancel () {
			this.force_close ();
		}

		void on_apply () {
			if (proxy_entry.visible && settings.proxy != proxy_entry.text)
				settings.proxy = proxy_entry.text;

			if (admin_row.active != original_admin_val)
				admin_changed (admin_row.active);

			on_cancel ();
		}
	}

	[GtkCallback] void on_settings_clicked () {
		var settings_dialog = new SettingsDialog (this.can_access_settings, settings.proxy, this.admin_mode);
		settings_dialog.admin_changed.connect (on_admin_change);
		settings_dialog.present (this);
	}

	void on_admin_change (bool new_val) {
		this.admin_mode = new_val;
	}
}
