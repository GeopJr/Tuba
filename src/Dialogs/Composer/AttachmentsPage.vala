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

	private Gtk.Spinner spinner;
	public GLib.ListStore attachments;
	public Adw.ToastOverlay toast_overlay;
	public bool media_sensitive { get; set; default = false; }

	bool _uploading = false;
	private bool uploading {
		get {
			return _uploading;
		}
		set {
			_uploading = value;
			on_attachments_changed ();
		}
	}

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

	public override void dispose () {
		if (list != null)
			list.bind_model (null, null);
		base.dispose ();
	}

	public override void on_build () {
		base.on_build ();

		var attach_button = new Button.with_label (_("Add Media")) {
			halign = Align.CENTER,
			sensitive = accounts.active.instance_info.compat_status_max_media_attachments > 0,
			// Empty state
			css_classes = { "pill" }
		};
		attach_button.clicked.connect (show_file_selector);

		empty_state = new Adw.StatusPage () {
			title = _("No Media"),
			vexpand = true,
			icon_name = icon_name,
			child = attach_button,
			css_classes = { "compact" }
		};

		// Non-empty state
		list = new ListBox () {
			selection_mode = SelectionMode.NONE
		};
		list.bind_model (attachments, on_create_list_item);

		add_media_action_button = new Gtk.Button () {
			icon_name = "tuba-plus-large-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			tooltip_text = _("Add Media"),
			css_classes = {"flat"}
		};
		add_media_action_button.clicked.connect (show_file_selector);

		var sensitive_media_button = new Gtk.ToggleButton () {
			icon_name = "tuba-eye-open-negative-filled-symbolic",
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER,
			// translators: sensitive as in not safe for work or similar
			tooltip_text = _("Mark media as sensitive"),
			css_classes = {"flat"}
		};
		sensitive_media_button.bind_property (
			"active",
			this,
			"media_sensitive",
			GLib.BindingFlags.SYNC_CREATE,
			(b, src, ref target) => {
				var sensitive_media_button_active = src.get_boolean ();
				target.set_boolean (sensitive_media_button_active);
				sensitive_media_button.icon_name = sensitive_media_button_active
					? "tuba-eye-not-looking-symbolic"
					: "tuba-eye-open-negative-filled-symbolic";
				sensitive_media_button.tooltip_text = sensitive_media_button_active
					// translators: sensitive as in not safe for work or similar
					? _("Unmark media as sensitive")
					: _("Mark media as sensitive");
				return true;
			}
		);

		bottom_bar.pack_start (add_media_action_button);
		bottom_bar.pack_start (sensitive_media_button);

		// State stack
		stack = new Adw.ViewStack ();
		stack.add_named (list, "list");
		stack.add_named (empty_state, "empty");

		spinner = new Gtk.Spinner () {
			spinning = false,
			halign = Gtk.Align.CENTER,
			valign = Gtk.Align.CENTER,
			vexpand = true,
			hexpand = true,
			width_request = 32,
			height_request = 32
		};
		stack.add_named (spinner, "spinner");

		toast_overlay = new Adw.ToastOverlay ();
		toast_overlay.child = stack;

		content.prepend (toast_overlay);

		if (status.media_attachments != null && status.media_attachments.size > 0) {
			foreach (var t_attachment in status.media_attachments) {
				attachments.append (t_attachment);
			}
		}
	}

	public override void on_pull () {
		on_attachments_changed ();
	}

	Widget on_create_list_item (Object item) {
		var attachment = item as API.Attachment;
		var attachment_widget = new AttachmentsPageAttachment (
			attachment.id,
			attachment.source_file,
			dialog,
			attachment,
			edit_mode && status.media_ids.contains (attachment.id)
		);

		attachment_widget.remove_from_model.connect (() => {
			uint indx;
			var found = attachments.find (item, out indx);
			if (found)
				attachments.remove (indx);
		});
		return attachment_widget;
	}

	void on_attachments_changed () {
		var attachments_size = attachments.get_n_items ();
		var is_empty = attachments_size < 1;
		if (is_empty || uploading) {
			stack.visible_child_name = uploading ? "spinner" : "empty";
			spinner.spinning = uploading;
			bottom_bar.hide ();
			can_publish = false;
		} else {
			stack.visible_child_name = "list";
			bottom_bar.show ();
			can_publish = true;

			// Disable the add media action button
			// if we went over the amount of media
			// the server allows.
			add_media_action_button.sensitive = accounts.active.instance_info.compat_status_max_media_attachments > attachments_size; // vala-lint=line-length
		}
	}

	File? last_used_folder;
	void show_file_selector () {
		var filter = new FileFilter () {
			name = _("All Supported Files")
		};

		var supported_mimes = new Gee.ArrayList<string>.wrap (SUPPORTED_MIMES);
		if (
			accounts.active.instance_info != null
			&& accounts.active.instance_info.configuration != null
			&& accounts.active.instance_info.configuration.media_attachments != null
			&& accounts.active.instance_info.configuration.media_attachments.supported_mime_types != null
			&& accounts.active.instance_info.configuration.media_attachments.supported_mime_types.size > 0
		) {
			supported_mimes = accounts.active.instance_info.configuration.media_attachments.supported_mime_types;
		}
		foreach (var mime_type in supported_mimes) {
			filter.add_mime_type (mime_type);
		}

		#if GTK_4_10
			var chooser = new FileDialog () {
				// translators: Open file
				title = _("Open"),
				modal = true,
				default_filter = filter
			};

			if (!Tuba.is_flatpak && last_used_folder != null)
				chooser.initial_folder = last_used_folder;

			chooser.open_multiple.begin (dialog, null, (obj, res) => {
				try {
					var files = chooser.open_multiple.end (res);
					if (!Tuba.is_flatpak && files.get_n_items () > 0)
						last_used_folder = ((File) files.get_item (0)).get_parent ();
		#else
			// translators: Open file
			var chooser = new FileChooserNative (_("Open"), dialog, Gtk.FileChooserAction.OPEN, null, null) {
				select_multiple = true,
				filter = filter,
				modal = true
			};

			if (!Tuba.is_flatpak && last_used_folder != null) {
				try {
					chooser.set_current_folder (last_used_folder);
				} catch {
					last_used_folder = null;
				}
			}

			chooser.response.connect (id => {
				switch (id) {
					case ResponseType.ACCEPT:
						var files = chooser.get_files ();
						if (!Tuba.is_flatpak)
							last_used_folder = chooser.get_current_folder ();
		#endif
					var selected_files_amount = files.get_n_items ();

					// We want to only upload as many attachments as the server
					// accepts based on the amount we have already uploaded.
					var allowed_attachments_amount = accounts.active.instance_info.compat_status_max_media_attachments - attachments.get_n_items (); // vala-lint=line-length
					var amount_to_add = selected_files_amount > allowed_attachments_amount
						? allowed_attachments_amount
						: selected_files_amount;

					File[] files_for_upload = {};

					for (var i = 0; i < amount_to_add; i++) {
						var file = files.get_item (i) as File;

						if (accounts.active.instance_info.compat_status_max_image_size > 0) {
							try {
								var file_info = file.query_info ("standard::size,standard::content-type", 0);
								var file_content_type = file_info.get_content_type ();

								if (file_content_type != null) {
									file_content_type = file_content_type.down ();
									var file_size = file_info.get_size ();
									var skip = (
										file_content_type.contains ("image/")
										&& file_size >= accounts.active.instance_info.compat_status_max_image_size
									) || (
										file_content_type.contains ("video/")
										&& file_size >= accounts.active.instance_info.compat_status_max_video_size
									);

									if (skip) {
										var toast = new Adw.Toast (
											_("File \"%s\" is bigger than the instance limit").printf (file.get_basename ())
										) {
											timeout = 0
										};
										toast_overlay.add_toast (toast);
										continue;
									}
								}

							} catch (Error e) {
								warning (e.message);
							}
						}

						files_for_upload += file;
					}

					var i = 0;
					foreach (var file in files_for_upload) {
						uploading = true;
						API.Attachment.upload.begin (file.get_uri (), (obj, res) => {
							try {
								var attachment = API.Attachment.upload.end (res);
								attachment.source_file = file;

								attachments.append (attachment);
							}
							catch (Error e) {
								warning (e.message);
								var toast = new Adw.Toast (e.message) {
									timeout = 0
								};
								toast_overlay.add_toast (toast);
							}
							i = i + 1;
							if (i == files_for_upload.length) uploading = false;
						});
					}
		#if GTK_4_10
				} catch (Error e) {
					// User dismissing the dialog also ends here so don't make it sound like
					// it's an error
					warning (@"Couldn't get the result of FileDialog for AttachmentsPage: $(e.message)");
				}
			});
		#else
						break;
				}
				chooser.unref ();
			});
			chooser.ref ();
			chooser.show ();
		#endif
	}

	public override void on_push () {
		status.clear_media ();
		status.media_attachments = new Gee.ArrayList<API.Attachment> ();

		for (var i = 0; i < attachments.get_n_items (); i++) {
			var attachment = attachments.get_item (i) as API.Attachment;
			var attachment_page_attachment_alt = ((AttachmentsPageAttachment) list.get_row_at_index (i).child).alt_text;

			attachment.description = attachment_page_attachment_alt;
			status.add_media (attachment.id, attachment.description);
			status.media_attachments.add (attachment);
		}
		status.sensitive = media_sensitive;
	}

	public override void on_modify_body (Json.Builder builder) {
		if (can_publish && this.visible) {
			builder.set_member_name ("sensitive");
			builder.add_boolean_value (status.sensitive);

			builder.set_member_name ("media_ids");
			builder.begin_array ();
			foreach (var m_id in status.media_ids) {
				builder.add_string_value (m_id);
			}
			builder.end_array ();
		}
	}
}
