using Gtk;

public class Tooth.AttachmentsPage : ComposerPage {

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

	public GLib.ListStore attachments;
	public Adw.ToastOverlay toast_overlay;
	public bool can_publish { get; set; default = false; }

	public AttachmentsPage () {
		Object (
			title: _("Media"),
			icon_name: "tooth-clip-attachment-symbolic"
		);

		attachments = new GLib.ListStore (typeof (API.Attachment));
		attachments.items_changed.connect (on_attachments_changed);
	}

	protected Adw.ViewStack stack;
	protected Adw.StatusPage empty_state;
	protected ListBox list;

	public override void on_build (Dialogs.Compose dialog, API.Status status) {
		base.on_build (dialog, status);

		// Empty state
		var attach_button = new Button.with_label (_("Add Media")) {
			halign = Align.CENTER
		};
		attach_button.add_css_class("pill");
		attach_button.clicked.connect (show_file_selector);

		empty_state = new Adw.StatusPage () {
			title = _("No Media"),
			description = _("Drag files here or click the button below"),
			vexpand = true,
			icon_name = icon_name,
			child = attach_button
		};
		empty_state.add_css_class ("compact");

		// Non-empty state
		list = new ListBox ();
		list.bind_model (attachments, on_create_list_item);

		var add_media_action_button = new Gtk.Button() {
			icon_name = "tooth-plus-large-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER
		};
		add_media_action_button.add_css_class ("flat");
		add_media_action_button.clicked.connect(show_file_selector);

		bottom_bar.pack_start (add_media_action_button);

		// State stack
		stack = new Adw.ViewStack ();
		stack.add_named (list, "list");
		stack.add_named (empty_state, "empty");

		toast_overlay = new Adw.ToastOverlay();
		toast_overlay.child = stack;

		content.prepend (toast_overlay);
	}

	public override void on_pull () {
		on_attachments_changed ();
	}

	Widget on_create_list_item (Object item) {
		var attachment = item as API.Attachment;
		var attachment_widget = new AttachmentsPageAttachment(attachment.id, attachment.source_file, dialog);
		attachment_widget.remove_from_model.connect(() => {
			uint indx;
			var found = attachments.find (item, out indx);
			if (found)
				attachments.remove(indx);
		});
		return attachment_widget;
	}

	void on_attachments_changed () {
		var is_empty = attachments.get_n_items () < 1;
		if (is_empty) {
			stack.visible_child_name = "empty";
			bottom_bar.hide ();
			can_publish = false;
		} else {
			stack.visible_child_name = "list";
			bottom_bar.show ();
			can_publish = true;
		}
	}

	void show_file_selector () {
		var filter = new FileFilter () {
			name = _("All Supported Files")
		};

		var supported_mimes = new Gee.ArrayList<string>.wrap(SUPPORTED_MIMES);
		if (accounts.active.instance_info != null && accounts.active.instance_info.configuration != null && accounts.active.instance_info.configuration.media_attachments != null && accounts.active.instance_info.configuration.media_attachments.supported_mime_types != null && accounts.active.instance_info.configuration.media_attachments.supported_mime_types.size > 0) {
			supported_mimes = accounts.active.instance_info.configuration.media_attachments.supported_mime_types;
		}
		foreach (var mime_type in supported_mimes) {
			filter.add_mime_type (mime_type);
		}

		var chooser = new FileChooserNative (_("Open"), dialog, Gtk.FileChooserAction.OPEN, null, null) {
			select_multiple = true,
			filter = filter
		};
		chooser.response.connect (id => {
			switch (id) {
				case ResponseType.ACCEPT:
					var files = chooser.get_files ();
					for (var i = 0; i < files.get_n_items (); i++) {
						var file = files.get_item (i) as File;

						if (accounts.active.instance_info.compat_status_max_image_size > 0) {
							try {
								var file_info = file.query_info ("standard::size,standard::content-type", 0);
								var file_content_type = file_info.get_content_type ();

								if (file_content_type != null) {
									file_content_type = file_content_type.down();
									var file_size = file_info.get_size();
									var skip = (file_content_type.contains("image/") &&
									file_size >= accounts.active.instance_info.compat_status_max_image_size) ||
									(file_content_type.contains("video/") &&
									file_size >= accounts.active.instance_info.compat_status_max_video_size);

									if (skip) {
										var toast = new Adw.Toast(_("File \"%s\" is bigger than the instance limit").printf(file.get_basename())) {
											timeout = 0
										};
										toast_overlay.add_toast(toast);
										continue;
									}
								}

							} catch (Error e) {
								warning (e.message);
							}
						}

						API.Attachment.upload.begin (file.get_uri (), (obj, res) => {
							try {
								var attachment = API.Attachment.upload.end (res);
								attachment.source_file = file;
								attachments.append (attachment);
							}
							catch (Error e) {
								warning (e.message);
								var toast = new Adw.Toast(e.message) {
									timeout = 0
								};
								toast_overlay.add_toast(toast);
							}
						});
					}
					break;
			}
			chooser.unref ();
		});
		chooser.ref ();
		chooser.show ();
	}

	public override void on_modify_req (Request req) {
		if (can_publish){
			for (var i = 0; i < attachments.get_n_items (); i++) {
				var attachment = attachments.get_item (i) as API.Attachment;
				req.with_form_data ("media_ids[]", attachment.id);
			}
		}
	}
}
