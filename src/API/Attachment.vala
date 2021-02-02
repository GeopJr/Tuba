public class Tootle.API.Attachment : Entity {

	// https://github.com/tootsuite/mastodon/blob/master/app/models/media_attachment.rb
	public const string[] SUPPORTED_MIMES = {
		"image/jpeg",
		"image/png",
		"image/gif",
		"video/webm",
		"video/mp4",
		"video/quicktime",
		"video/ogg",
		"video/webm",
		"video/quicktime",
		"audio/wave",
		"audio/wav",
		"audio/x-wav",
		"audio/x-pn-wave",
		"audio/ogg",
		"audio/mpeg",
		"audio/mp3",
		"audio/webm",
		"audio/flac",
		"audio/aac",
		"audio/m4a",
		"audio/x-m4a",
		"audio/mp4",
		"audio/3gpp",
		"video/x-ms-asf"
	};

	public string id { get; set; }
	public string kind { get; set; }
	public string url { get; set; }
	public string? description { get; set; }
	public string? _preview_url { get; set; }
	public string? preview_url {
		set { this._preview_url = value; }
		get { return (this._preview_url == null || this._preview_url == "") ? url : _preview_url; }
	}

	public static Attachment from (Json.Node node) throws Error {
		return Entity.from_json (typeof (API.Attachment), node) as API.Attachment;
	}

	public static async Attachment upload (string uri, string title, string? descr) throws Error {
		message (@"Uploading new media: $(uri)...");

		uint8[] contents;
		string mime;
		GLib.FileInfo type;
		try {
			GLib.File file = File.new_for_uri (uri);
			file.load_contents (null, out contents, null);
			type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
			mime = type.get_content_type ();
		}
		catch (Error e) {
			throw new Oopsie.USER (_("Can't open file $file:\n$reason")
				.replace ("$file", title)
				.replace ("$reason", e.message)
			);
		}

		var descr_param = "";
		if (descr != null && descr.replace (" ", "") != "") {
			descr_param = "?description=" + HtmlUtils.uri_encode (descr);
		}

		var buffer = new Soup.Buffer.take (contents);
		var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);
		var url = @"$(accounts.active.instance)/api/v1/media$descr_param";
		var msg = Soup.Form.request_new_from_multipart (url, multipart);
		msg.request_headers.append ("Authorization", @"Bearer $(accounts.active.access_token)");

		string? error = null;
		network.queue (msg,
		(sess, mess) => {
			upload.callback ();
		},
		(code, reason) => {
			error = reason;
			upload.callback ();
		});

		yield;

		if (error != null)
			throw new Oopsie.INSTANCE (error);
		else {
			var node = network.parse_node (msg);
			var entity = API.Attachment.from (node);
			message (@"OK! ID $(entity.id)");
			return entity;
		}
	}

}
