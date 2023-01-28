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
		content.prepend (stack);
	}

	public override void on_pull () {
		on_attachments_changed ();
	}

	Widget on_create_list_item (Object item) {
		var attachment = item as API.Attachment;
		var attachment_widget = new AttachmentsPageAttachment(attachment.source_file, dialog);
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
		} else {
			stack.visible_child_name = "list";
			bottom_bar.show ();
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
					for (var i = 0; i < chooser.get_files ().get_n_items (); i++) {
						var file = files.get_item (i) as File;
						var attachment = API.Attachment.upload (file);
						attachments.append (attachment);
					}
					break;
			}
			chooser.unref ();
		});
		chooser.ref ();
		chooser.show ();
	}

}
