public class Tuba.Dialogs.Components.AttachmentsBin : Gtk.Grid, Attachable {
	public bool uploading { get; set; default = false; }
	public bool is_empty { get { return attachment_widgets.size == 0; } }

	// https://github.com/tootsuite/mastodon/blob/master/app/models/media_attachment.rb
	public const string[] SUPPORTED_MIMES = {
		"image/jpeg",
		"image/png",
		"image/gif",
		"image/heic",
		"image/heif",
		"image/webp",
		"image/avif",
		"audio/wave",
		"audio/wav",
		"audio/x-wav",
		"audio/x-pn-wave",
		"audio/vnd.wave",
		"audio/ogg",
		"audio/vorbis",
		"audio/mpeg",
		"audio/mp3",
		"audio/webm",
		"audio/flac",
		"audio/aac",
		"audio/m4a",
		"audio/x-m4a",
		"audio/mp4",
		"audio/3gpp",
		"video/x-ms-asf",
		"video/quicktime",
		"video/webm",
		"video/mp4",
		"video/ogg"
	};
	private Gtk.FileFilter filter = new Gtk.FileFilter () {
			name = _("All Supported Files")
	};
	private Gee.ArrayList<string> supported_mimes = new Gee.ArrayList<string>.wrap (SUPPORTED_MIMES);

	Gee.ArrayList<Components.Attachment> attachment_widgets = new Gee.ArrayList<Components.Attachment> ();
	construct {
		populate_filter ();
		this.column_spacing = this.row_spacing = 12;
		this.row_homogeneous = this.column_homogeneous = true;

		// HACK: 2 cols otherwise when there's
		//		 only 1 attachment, it expands
		this.attach (new Adw.Bin (), 0, 0);
		this.attach (new Adw.Bin (), 1, 0);
	}

	private void add_attachment (Components.Attachment attachment) {
		attachment.switch_place.connect (on_switch_place);
		attachment.delete_me.connect (on_delete);
		this.attach (attachment, attachment_widgets.size % 2, (int) Math.floor (attachment_widgets.size / 2));
		attachment_widgets.add (attachment);
		this.notify_property ("is-empty");
		attachment.play_animation ();
	}

	private void on_switch_place (Components.Attachment from, Components.Attachment to) {
		int from_column;
		int from_row;
		this.query_child (from, out from_column, out from_row, null, null);

		int to_column;
		int to_row;
		this.query_child (to, out to_column, out to_row, null, null);

		this.remove (from);
		this.remove (to);

		this.attach (to, from_column, from_row);
		this.attach (from, to_column, to_row);

		int from_index = attachment_widgets.index_of (from);
		int to_index = attachment_widgets.index_of (to);

		var temp = attachment_widgets[from_index];
    	attachment_widgets[from_index] = attachment_widgets[to_index];
    	attachment_widgets[to_index] = temp;
	}

	private void on_delete (Components.Attachment attachment) {
		this.remove (attachment);
		attachment_widgets.remove (attachment);
		this.notify_property ("is-empty");
	}

	private void populate_filter () {
		if (
			accounts.active.instance_info != null
			&& accounts.active.instance_info.configuration != null
			&& accounts.active.instance_info.configuration.media_attachments != null
			&& accounts.active.instance_info.configuration.media_attachments.supported_mime_types != null
			&& accounts.active.instance_info.configuration.media_attachments.supported_mime_types.size > 0
			// if the only supported type is octet-stream, assume everything
			&& !(
				accounts.active.instance_info.configuration.media_attachments.supported_mime_types.size == 1
				&& accounts.active.instance_info.configuration.media_attachments.supported_mime_types[0] == "application/octet-stream"
			)
		) {
			supported_mimes = accounts.active.instance_info.configuration.media_attachments.supported_mime_types;
		}

		foreach (var mime_type in supported_mimes) {
			filter.add_mime_type (mime_type.down ());
		}
	}

	private async void upload_files (File[] files) {
		var selected_files_amount = files.length;
		if (selected_files_amount == 0) return;

		// We want to only upload as many attachments as the server
		// accepts based on the amount we have already uploaded.
		var allowed_attachments_amount = accounts.active.instance_info.compat_status_max_media_attachments - attachment_widgets.size;

		bool reached_limit = false;
		File[] files_for_upload = {};
		foreach (File file in files) {
			if (accounts.active.instance_info.compat_status_max_image_size > 0) {
				try {
					var file_info = file.query_info ("standard::size,standard::content-type", 0);
					var file_content_type = file_info.get_content_type ();

					if (file_content_type != null) {
						file_content_type = file_content_type.down ();
						if (!supported_mimes.contains (file_content_type)) continue;

						var file_size = file_info.get_size ();
						var skip = (
							file_content_type.contains ("image/")
							&& file_size >= accounts.active.instance_info.compat_status_max_image_size
						) || (
							file_content_type.contains ("video/")
							&& file_size >= accounts.active.instance_info.compat_status_max_video_size
						);

						if (skip) {
							toast (new Adw.Toast (_("File \"%s\" is bigger than the instance limit").printf (file.get_basename ())));
							continue;
						}
					}

				} catch (Error e) {
					warning (e.message);
				}
			}

			// we want to add a max of allowed_attachments_amount
			// previously this check would happen in advance, but
			// we can be more liberal about this and instead check
			// all of them and stop if we run out or we reach
			// allowed_attachments_amount.
			//
			// this way, if a user selected 5 items, can only upload
			// a max of 4, but one of them does not pass the check,
			// it will still pass since <= 4 were allowed in
			files_for_upload += file;
			if (files_for_upload.length >= allowed_attachments_amount) {
				reached_limit = true;
				break;
			}
		}

		if (reached_limit) {
			// translators: the variable is the total amount of attachments allowed (a number)
			toast (new Adw.Toast (_("Attachment limit reached (%lld)").printf (accounts.active.instance_info.compat_status_max_media_attachments)) {
				timeout = 3
			});
		}

		this.uploading = true;
		for (int i = 0; i < files_for_upload.length; i++) {
			var file13 = files_for_upload[i];

			try {
				var attachment = new Components.Attachment ();
				attachment.upload.begin (file13);
				add_attachment (attachment);
			} catch (Error e) {
				toast (new Adw.Toast (e.message));
			}
		}
		this.uploading = false;
	}

	public void show_file_selector () {
		var chooser = new Gtk.FileDialog () {
			// translators: Open file
			title = _("Open"),
			modal = true,
			default_filter = filter
		};
		chooser.open_multiple.begin (app.main_window, null, (obj, res) => {
			try {
				var files = chooser.open_multiple.end (res);

				File[] files_to_upload = {};
				var amount_of_files = files.get_n_items ();
				for (var i = 0; i < amount_of_files; i++) {
					var file = files.get_item (i) as File;

					if (file != null)
						files_to_upload += file;
				}

				upload_files.begin (files_to_upload);
			} catch (Error e) {
				// User dismissing the dialog also ends here so don't make it sound like
				// it's an error
				warning (@"Couldn't get the result of FileDialog for AttachmentsPage: $(e.message)");
			}
		});
	}
}
