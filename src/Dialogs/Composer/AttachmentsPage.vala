using Gtk;

public class Tuba.AttachmentsPage : ComposerPage {

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
	public bool media_sensitive { get; set; default = false; }

	public AttachmentsPage () {
		Object (
			title: _("Media"),
			icon_name: "tuba-clip-attachment-symbolic"
		);

		attachments = new GLib.ListStore (typeof (API.Attachment));
		attachments.items_changed.connect (on_attachments_changed);
	}

	protected Adw.ViewStack stack;
	protected Adw.StatusPage empty_state;
	protected ListBox list;
	protected Gtk.Button add_media_action_button;

	public override void on_build (Dialogs.Compose dialog, API.Status status) {
		base.on_build (dialog, status);

		var attach_button = new Button.with_label (_("Add Media")) {
			halign = Align.CENTER,
			sensitive = accounts.active.instance_info.compat_status_max_media_attachments > 0
		};
		// Empty state
		attach_button.add_css_class("pill");
		attach_button.clicked.connect (show_file_selector);

		empty_state = new Adw.StatusPage () {
			title = _("No Media"),
			vexpand = true,
			icon_name = icon_name,
			child = attach_button
		};
		empty_state.add_css_class ("compact");

		// Non-empty state
		list = new ListBox ();
		list.bind_model (attachments, on_create_list_item);

		add_media_action_button = new Gtk.Button() {
			icon_name = "tuba-plus-large-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Add Media"),
			css_classes = {"flat"}
		};
		add_media_action_button.clicked.connect(show_file_selector);

		var sensitive_media_button = new Gtk.ToggleButton() {
			icon_name = "tuba-eye-open-negative-filled-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			// translators: sensitive as in not safe for work or similar
			tooltip_text = _("Mark media as sensitive"),
			css_classes = {"flat"}
		};
		sensitive_media_button.bind_property ("active", this, "media_sensitive", GLib.BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			var sensitive_media_button_active = src.get_boolean ();
			target.set_boolean (sensitive_media_button_active);
			sensitive_media_button.icon_name = sensitive_media_button_active ? "tuba-eye-not-looking-symbolic" : "tuba-eye-open-negative-filled-symbolic";
			// translators: sensitive as in not safe for work or similar
			sensitive_media_button.tooltip_text = sensitive_media_button_active ? _("Unmark media as sensitive") : _("Mark media as sensitive");
			return true;
		});

		bottom_bar.pack_start (add_media_action_button);
		bottom_bar.pack_start (sensitive_media_button);

		// State stack
		stack = new Adw.ViewStack ();
		stack.add_named (list, "list");
		stack.add_named (empty_state, "empty");

		toast_overlay = new Adw.ToastOverlay();
		toast_overlay.child = stack;

		content.prepend (toast_overlay);

		if (status.has_media()) {
			foreach (var t_attachment in status.media_attachments) {
                attachments.append(t_attachment);
            }
		}
	}

	public override void on_pull () {
		on_attachments_changed ();
	}

	Widget on_create_list_item (Object item) {
		var attachment = item as API.Attachment;
		var attachment_widget = new AttachmentsPageAttachment(attachment.id, attachment.source_file, dialog, attachment);
		attachment_widget.remove_from_model.connect(() => {
			uint indx;
			var found = attachments.find (item, out indx);
			if (found)
				attachments.remove(indx);
		});
		return attachment_widget;
	}

	void on_attachments_changed () {
		var attachments_size = attachments.get_n_items ();
		var is_empty = attachments_size < 1;
		if (is_empty) {
			stack.visible_child_name = "empty";
			bottom_bar.hide ();
			can_publish = false;
		} else {
			stack.visible_child_name = "list";
			bottom_bar.show ();
			can_publish = true;

			// Disable the add media action button
			// if we went over the amount of media
			// the server allows.
			add_media_action_button.sensitive = accounts.active.instance_info.compat_status_max_media_attachments > attachments_size;
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

		// translators: Open file
		var chooser = new FileChooserNative (_("Open"), dialog, Gtk.FileChooserAction.OPEN, null, null) {
			select_multiple = true,
			filter = filter
		};
		chooser.response.connect (id => {
			switch (id) {
				case ResponseType.ACCEPT:
					var files = chooser.get_files ();
					var selected_files_amount = files.get_n_items ();

					// We want to only upload as many attachments as the server
					// accpets based on the amount we have already uploaded.
					var allowed_attachments_amount = accounts.active.instance_info.compat_status_max_media_attachments - attachments.get_n_items ();
					var amount_to_add = selected_files_amount > allowed_attachments_amount ? allowed_attachments_amount : selected_files_amount;

					for (var i = 0; i < amount_to_add; i++) {
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

			if (media_sensitive) {
				req.with_form_data ("sensitive", "true");
			}
		}
	}
}
