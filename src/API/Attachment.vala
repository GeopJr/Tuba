public class Tootle.API.Attachment : Entity, Widgetizable {

	public string id { get; set; }
	public string kind { get; set; default = "unknown"; }
	public string url { get; set; }
	public string? description { get; set; }
	public string? t_preview_url { get; set; }
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

	public static Attachment upload (File file) {
		return new Attachment () {
			source_file = file
		};
	}

	// public static async Attachment upload (string uri, string title, string? descr) throws Error {
	// 	message (@"Uploading new media: $(uri)...");

	// 	uint8[] contents;
	// 	string mime;
	// 	GLib.FileInfo type;
	// 	try {
	// 		GLib.File file = File.new_for_uri (uri);
	// 		file.load_contents (null, out contents, null);
	// 		type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
	// 		mime = type.get_content_type ();
	// 	}
	// 	catch (Error e) {
	// 		throw new Oopsie.USER (_("Can't open file $file:\n$reason")
	// 			.replace ("$file", title)
	// 			.replace ("$reason", e.message)
	// 		);
	// 	}

	// 	var descr_param = "";
	// 	if (descr != null && descr.replace (" ", "") != "") {
	// 		descr_param = "?description=" + HtmlUtils.uri_encode (descr);
	// 	}

	// 	var buffer = new Soup.Buffer.take (contents);
	// 	var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
	// 	multipart.append_form_file ("file", mime.replace ("/", "."), mime, buffer);
	// 	var url = @"$(accounts.active.instance)/api/v1/media$descr_param";
	// 	var msg = Soup.Form.request_new_from_multipart (url, multipart);
	// 	msg.request_headers.append ("Authorization", @"Bearer $(accounts.active.access_token)");

	// 	string? error = null;
	// 	network.queue (msg,
	// 		(sess, mess) => {
	// 			upload.callback ();
	// 		},
	// 		(code, reason) => {
	// 			error = reason;
	// 			upload.callback ();
	// 		});

	// 	yield;

	// 	if (error != null)
	// 		throw new Oopsie.INSTANCE (error);
	// 	else {
	// 		var node = network.parse_node (msg);
	// 		var entity = accounts.active.create_entity<API.Attachment> (node);
	// 		message (@"OK! ID $(entity.id)");
	// 		return entity;
	// 	}
	// }

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
