public class Tuba.API.Attachment : Entity, Widgetizable {
	public class Meta : Entity {
		public class Focus : Entity {
			public float x { get; set; }
			public float y { get; set; }
		}

		public Focus? focus { get; set; }
	}

	public string id { get; set; }
	public string kind { get; set; default = "unknown"; }
	public string url { get; set; }
	public string? description { get; set; }
	public Meta? meta { get; set; }
	public string? blurhash { get; set; default=null; }
	private string? t_preview_url { get; set; }
	public string? preview_url {
		set { this.t_preview_url = value; }
		get { return (this.t_preview_url == null || this.t_preview_url == "") ? url : t_preview_url; }
	}
	public string? tuba_translated_alt_text { get; set; default = null; }
	public bool tuba_is_report { get; set; default = false; }

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

	public static async Attachment upload (string? uri, Bytes? bytes, string? mime_type) throws Error {
		assert_true (uri != null || (bytes != null && mime_type != null));

		Bytes buffer;
		string mime;

		if (uri != null) {
			debug (@"Uploading new media: $(uri)…");
			uint8[] contents;
			try {
				GLib.File file = File.new_for_uri (uri);
				file.load_contents (null, out contents, null);
				GLib.FileInfo type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
				mime = type.get_content_type ();
			} catch (Error e) {
				throw new Oopsie.USER ("Can't open file %s:\n%s".printf (uri, e.message));
			}

			buffer = new Bytes.take (contents);
		} else {
			buffer = bytes;
			mime = mime_type;
		}

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
