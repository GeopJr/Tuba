using Soup;
using Gee;

public class Tooth.Request : Soup.Message {

	public string url { set; get; }
	public weak InstanceAccount? account { get; set; default = null; }
	Network.SuccessCallback? cb;
	Network.ErrorCallback? error_cb;
	HashMap<string, string>? pars;
	Soup.Multipart? form_data;

	weak Gtk.Widget? ctx;
	bool has_ctx = false;

	public Request.GET (string url) {
		Object (method: "GET", url: url);
	}
	public Request.POST (string url) {
		Object (method: "POST", url: url);
	}
	public Request.PUT (string url) {
		Object (method: "PUT", url: url);
	}
	public Request.DELETE (string url) {
		Object (method: "DELETE", url: url);
	}

	// ~Request () {
	// 	message ("Destroy req: "+url);
	// }

	public Request then (owned Network.SuccessCallback cb) {
		this.cb = (owned) cb;
		return this;
	}

	public Request then_parse_array (owned Network.NodeCallback _cb) {
		this.cb = (sess, msg) => {
			Network.parse_array (msg, (owned) _cb);
		};
    return this;
}

	public Request with_ctx (Gtk.Widget ctx) {
		this.has_ctx = true;
		this.ctx = ctx;
		this.ctx.destroy.connect (() => {
			network.cancel (this);
			this.ctx = null;
		});
		return this;
	}

	public Request on_error (owned Network.ErrorCallback cb) {
		this.error_cb = (owned) cb;
		return this;
	}

	public Request with_account (InstanceAccount? account = null) {
		this.account = account;
		return this;
	}

	public Request with_param (string name, string val) {
		if (pars == null)
			pars = new HashMap<string, string> ();
		pars[name] = val;
		return this;
	}

	public Request with_form_data (string name, string val) {
		if (form_data == null)
			form_data = new Soup.Multipart(FORM_MIME_TYPE_MULTIPART);
		form_data.append_form_string(name, val);
		return this;
	}

	public Request exec () {
		var parameters = "";
		if (pars != null) {
			if ("?" in url)
				parameters = "";
			else
				parameters = "?";

			var parameters_counter = 0;
			pars.@foreach (entry => {
				parameters_counter++;
				var key = (string) entry.key;
				var val = (string) entry.value;
				parameters += @"$key=$val";

				if (parameters_counter < pars.size)
					parameters += "&";

				return true;
			});
		}

		if (form_data != null)
			form_data.to_message(request_headers, request_body);

		if (account != null && account.access_token != null) {
			request_headers.append ("Authorization", @"Bearer $(account.access_token)");
		}

		if (!("://" in url))
			url = account.instance + url;

		uri = new URI (url + parameters);
		network.queue (this, (owned) cb, (owned) error_cb);
		return this;
	}

	public async Request await () throws Error {
		string? error = null;
		this.error_cb = (code, reason) => {
			error = reason;
			await.callback ();
		};
		this.cb = (sess, msg) => {
			await.callback ();
		};
		this.exec ();
		yield;

		if (error != null)
			throw new Oopsie.INSTANCE (error);
		else
			return this;
	}

	public static string array2string (Gee.ArrayList<string> array, string key) {
		var result = "";
		array.@foreach (i => {
			result += @"$key[]=$i";
			if (array.index_of (i)+1 != array.size)
				result += "&";
			return true;
		});
		return result;
	}

}
