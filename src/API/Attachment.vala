public class Tuba.API.Attachment : Entity, Widgetizable {

	public string id { get; set; }
	public string kind { get; set; default = "unknown"; }
	public string url { get; set; }
	public string? description { get; set; }
	public string? blurhash { get; set; default=null; }
	private string? t_preview_url { get; set; }
	public string? preview_url {
		set { this.t_preview_url = value; }
		get { return (this.t_preview_url == null || this.t_preview_url == "") ? url : t_preview_url; }
	}

	public File? source_file { get; set; }

	public bool is_published {
		get {
			return this.source_file == null;
		}
	}

	//  public static Attachment upload (File file) {
	//  	return new Attachment () {
	//  		source_file = file
	//  	};
	//  }

	public static async Attachment upload (string uri) throws Error {
		debug (@"Uploading new media: $(uri)…");

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
			throw new Oopsie.USER ("Can't open file %s:\n%s".printf (uri, e.message));
		}

		var buffer = new Bytes.take (contents);
		var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);
		var url = @"$(accounts.active.instance)/api/v1/media";
		var msg = new Soup.Message.from_multipart (url, multipart);
		msg.request_headers.append ("Authorization", @"Bearer $(accounts.active.access_token)");

		string? error = null;
		InputStream? in_stream = null;
		network.queue (msg, null,
			(t_is) => {
				in_stream = t_is;
				upload.callback ();
			},
			(code, reason) => {
				error = reason;
				upload.callback ();
			});

		yield;

		if (error != null || in_stream == null)
			throw new Oopsie.INSTANCE (error);
		else {
			var parser = Network.get_parser_from_inputstream (in_stream);
			var node = network.parse_node (parser);
			var entity = accounts.active.create_entity<API.Attachment> (node);
			debug (@"OK! ID $(entity.id)");
			return entity;
		}
	}

	public override Gtk.Widget to_widget () {
		if (preview_url != null) {
			return new Widgets.Attachment.Image () {
				entity = this
			};
		}

		return new Widgets.Attachment.Item () {
			entity = this
		};
	}
}
