public class Tuba.RequestV2 : GLib.Object {
	public enum Method {
		GET,
		POST,
		PUT,
		DELETE,
		PATCH;

		public string to_string () {
			switch (this) {
				case GET: return "GET";
				case POST: return "POST";
				case PUT: return "PUT";
				case DELETE: return "DELETE";
				case PATCH: return "PATCH";
				default: assert_not_reached ();
			}
		}
	}

	public Method method { get; private set; default = GET; }
	public string url { get; private set; }
	public Soup.MessagePriority priority { get; set; default = NORMAL; }
	public GLib.Cancellable? cancellable { get; set; default = null; } // priv?
	public InstanceAccount? account { get; set; default = null; }
	public string? force_token { get; set; default = null; }
	public bool no_auth { get; set; default = false; }
	public bool cache { get; set; default = true; }
	public weak Gtk.Widget? ctx {
		set {
			this._ctx = value;
			if (this._ctx != null) {
				this._ctx.destroy.connect (on_ctx_destroy);
			}
		}
	}

	private GLib.HashTable<string,string> parameters = new GLib.HashTable<string,string> (str_hash, str_equal);
	private string? content_type { get; set; default = null; }
	private weak Gtk.Widget? _ctx = null;
	private Soup.Multipart? form_data = null;
	private Bytes? body_bytes = null;

	private void on_ctx_destroy () {
		this.cancellable.cancel ();
		this.ctx = null;
	}

	public RequestV2 (string url, Method method = GET) {
		this.method = method;
		this.url = url;
	}

	public void add_parameter (string key, string value) {
		parameters.insert (
			GLib.Uri.escape_string (key, "[]"),
			GLib.Uri.escape_string (value)
		);
	}

	public bool remove_parameter (string key) {
		string final_key = GLib.Uri.escape_string (key, "[]");
		if (!this.parameters.contains (final_key)) return false;

		return parameters.foreach_remove ((p_key, p_val) => {
			return p_key == final_key || p_key == @"$final_key[]";
		}) > 0;
	}

	public void add_parameter_array (string key, string[] values) {
		if (values.length == 0) return;

		string final_key = key;
		if (!final_key.has_suffix ("[]")) final_key = @"$key[]";
		foreach (string value in values) {
			add_parameter (final_key, value);
		}
	}

	public void add_form_data (string name, string val) {
		if (this.form_data == null)
			this.form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		this.form_data.append_form_string (name, val);
	}

	public void add_form_data_file (string name, string mime, Bytes buffer) {
		if (this.form_data == null)
			this.form_data = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		this.form_data.append_form_file (name, mime.replace ("/", "."), mime, buffer);
	}

	public void set_body (string? content_type, Bytes? bytes) {
		this.content_type = content_type;
		body_bytes = bytes;
	}

	public void set_body_from_json (Json.Builder json_builder) {
		Json.Generator generator = new Json.Generator ();
		generator.set_root (json_builder.get_root ());
		set_body ("application/json", new Bytes.take (generator.to_data (null).data));
	}

	public async bool exec (out GLib.InputStream in_stream, out Soup.MessageHeaders response_headers) throws GLib.Error, Oopsie {
		if (this.cancellable != null && !this.cancellable.is_cancelled ()) this.cancellable.cancel ();
		this.cancellable = new GLib.Cancellable ();

		string final_url = build_final_url ();
		Soup.Message message;
		if (this.form_data == null) {
			GLib.Uri final_uri = GLib.Uri.parse (final_url, UriFlags.ENCODED_PATH | UriFlags.ENCODED_QUERY);
			message = new Soup.Message.from_uri (this.method.to_string (), final_uri);
		} else {
			message = new Soup.Message.from_multipart (final_url, this.form_data);
			// POST is default for multipart
			if (this.method != POST) message.method = this.method.to_string ();
		}

		if (!no_auth) {
			if (force_token != null) {
				message.request_headers.append ("Authorization", @"Bearer $force_token");
			} else if (account != null && account.access_token != null) {
				message.request_headers.append ("Authorization", @"Bearer $(account.access_token)");
			}
		} else {
			message.request_headers.remove ("Authorization");
		}

		if (!cache) message.disable_feature (typeof (Soup.Cache));
		message.priority = priority;

		if (this.content_type != null && this.body_bytes != null)
			message.set_request_body_from_bytes (this.content_type, this.body_bytes);

		return yield network.queue_v2 (message, this.cancellable, out in_stream, out response_headers);
		// TODO: ensure body_bytes = ctx = null...
	}

	private string build_final_url () {
		string final_url = this.account != null && this.url.has_prefix ("/")
			? @"$(this.account.instance)$(this.url)"
			: this.url;
		final_url += @"$("?" in this.url ? "&" : "?")$(parameters_to_string ())";
		return final_url;
	}

	private string parameters_to_string () {
		string res = "";
		if (this.parameters.length == 0) return res;

		int i = 0;
		this.parameters.foreach ((key, val) => {
			i++;
			res += @"$key=$val"; // already escaped
			if (i < this.parameters.length) res += "&";
		});

		return (owned) res;
	}
}
