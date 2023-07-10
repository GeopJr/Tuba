public class Tuba.Dialogs.ProfileEdit : Adw.Window {
	~ProfileEdit () {
		message (@"Destroying ProfileEdit for $(profile.handle)");
	}

	public class Avatar : Adw.Bin {
		Adw.Avatar avatar;

		private string _url = "";
		public string url {
			get {
				return _url;
			}

			set {
				_url = value;
				image_cache.request_paintable (value, on_cache_response);
			}
		}

		public string text {
			get { return avatar.text; }
			set { avatar.text = value; }
		}

		public int size {
			get { return avatar.size; }
			set { avatar.size = value; }
		}

		public Gdk.Paintable? custom_image {
			get { return avatar.custom_image; }
			set { avatar.custom_image = value; }
		}

		construct {
			avatar = new Adw.Avatar (48, "d", false);
			child = avatar;
			halign = valign = Gtk.Align.CENTER;
		}

		void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
			custom_image = data;
		}
	}

	public class Field : Adw.ExpanderRow {
		~Field () {
			message ("Destroying ProfileEdit.Field");
		}

		Adw.EntryRow key_row;
		Adw.EntryRow value_row;

		public string key {
			get {
				return key_row.text ?? "";
			}
		}

		public string value {
			get {
				return value_row.text ?? "";
			}
		}

		public bool valid {
			get {
				return key.length > 0
					&& value.length > 0
					&& key.length <= max_key_length
					&& value.length <= max_value_length;
			}
		}

		int64 max_key_length;
		int64 max_value_length;
		public Field (string? t_key, string? t_value, int64 t_max_key_length, int64 t_max_value_length) {
			max_key_length = t_max_key_length;
			max_value_length = t_max_value_length;
			expanded = t_key != null || t_value != null;
			key_row = new Adw.EntryRow () {
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				title = _("Label"),
				text = t_key ?? ""
			};
			key_row.changed.connect (update_valid_style);

			value_row = new Adw.EntryRow () {
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				title = _("Content"),
				text = t_value ?? ""
			};
			value_row.changed.connect (update_valid_style);

			add_row (key_row);
			add_row (value_row);
			update_valid_style ();
		}

		void update_valid_style () {
			Tuba.toggle_css (this, !valid, "error");
		}
	}

	private Avatar avi { get; set; }
	private Adw.EntryRow name_row { get; set; }
	private Adw.ExpanderRow bio_row { get; set; }
	private Gtk.TextView bio_text_view { get; set; }
	private Adw.PreferencesGroup fields_box { get; set; }
	private Widgets.Background background { get; set; }

	Gtk.FileFilter filter = new Gtk.FileFilter () {
		name = _("All Supported Files")
	};

	construct {
		filter.add_mime_type ("image/jpeg");
		filter.add_mime_type ("image/png");
		filter.add_mime_type ("image/gif");

		add_css_class ("profile-editor");
		add_binding_action (Gdk.Key.Escape, 0, "window.close", null);

		title = _("Edit Profile");
		modal = true;
		transient_for = app.main_window;
		default_width = 460;
		default_height = 520;

		var content_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
			margin_top = 24,
			margin_bottom = 24
		};

		var profile_info_box = new Gtk.ListBox () {
			css_classes = { "boxed-list" },
			selection_mode = Gtk.SelectionMode.NONE
		};

		name_row = new Adw.EntryRow () {
			input_purpose = Gtk.InputPurpose.FREE_FORM,
			title = _("Display Name")
		};
		name_row.changed.connect (on_name_row_changed);

		bio_row = new Adw.ExpanderRow () {
			title = _("Bio"),
			expanded = false
		};

		bio_text_view = new Gtk.TextView () {
			margin_bottom = 6,
			margin_top = 6,
			margin_end = 6,
			margin_start = 6,
			wrap_mode = Gtk.WrapMode.WORD_CHAR,
			css_classes = { "background-none" },
			accepts_tab = false
		};
		bio_row.add_row (bio_text_view);
		bio_text_view.buffer.changed.connect (on_bio_text_changed);

		var custom_emoji_picker = new Widgets.CustomEmojiChooser ();
		var custom_emoji_button = new Gtk.MenuButton () {
			icon_name = "tuba-cat-symbolic",
			popover = custom_emoji_picker,
			tooltip_text = _("Custom Emoji Picker"),
			css_classes = { "circular" },
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER
		};
		custom_emoji_picker.emoji_picked.connect (on_bio_emoji_picked);
		bio_row.bind_property ("expanded", custom_emoji_button, "sensitive", GLib.BindingFlags.SYNC_CREATE);
		// FIXME: add_suffix on libadwaita 1.4
		bio_row.add_action (custom_emoji_button);

		profile_info_box.append (name_row);
		profile_info_box.append (bio_row);

		fields_box = new Adw.PreferencesGroup () {
			title = _("Fields")
		};

		content_box.append (create_header_avi_widget ());
		content_box.append (profile_info_box);
		content_box.append (fields_box);

		var clamp = new Adw.Clamp () {
			child = content_box,
			tightening_threshold = 100,
			valign = Gtk.Align.START
		};
		var scroller = new Gtk.ScrolledWindow () {
			hexpand = true,
			vexpand = true
		};
		scroller.child = clamp;

		var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
		var headerbar = new Adw.HeaderBar () {
			show_end_title_buttons = false,
			show_start_title_buttons = false
		};

		var save_btn = new Gtk.Button.with_label (_("Save")) {
			css_classes = { "suggested-action" }
		};
		save_btn.clicked.connect (on_save_clicked);

		var close_btn = new Gtk.Button.with_label (_("Close"));
		close_btn.clicked.connect (on_close);

		headerbar.pack_start (close_btn);
		headerbar.pack_end (save_btn);

		box.append (headerbar);
		box.append (scroller);

		content = box;
	}

	Gtk.Widget create_header_avi_widget () {
		var avi_edit_button = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
			css_classes = { "osd", "circular" },
			tooltip_text = _("Edit Profile Picture"),
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER
		};
		avi_edit_button.clicked.connect (on_avi_button_clicked);

		avi = new Avatar () {
			size = 120
		};

		var avi_overlay = new Gtk.Overlay () {
			child = avi,
			valign = Gtk.Align.CENTER,
			halign = Gtk.Align.CENTER
		};
		avi_overlay.add_overlay (avi_edit_button);

		var background_edit_button = new Gtk.Button.from_icon_name ("document-edit-symbolic") {
			css_classes = { "osd", "circular" },
			tooltip_text = _("Edit Header Picture"),
			valign = Gtk.Align.START,
			halign = Gtk.Align.START,
			margin_start = 6,
			margin_top = 6
		};
		background_edit_button.clicked.connect (on_header_button_clicked);

		background = new Widgets.Background () {
			height_request = 128,
			css_classes = { "background-cover" }
		};

		var background_overlay = new Gtk.Overlay () {
			vexpand = true,
			hexpand = true,
			child = background
		};
		background_overlay.add_overlay (background_edit_button);

		var images_overlay = new Gtk.Overlay () {
			child = background_overlay
		};
		images_overlay.add_overlay (avi_overlay);

		return images_overlay;
	}

	void on_close () {
		destroy ();
	}

	void on_avi_button_clicked () {
		choose_file (false);
	}

	void on_header_button_clicked () {
		choose_file (true);
	}

	void on_save_clicked () {
		this.sensitive = false;
		save.begin ((obj, res) => {
			try {
				save.end (res);
			} catch (GLib.Error e) {
				critical (e.message);
				var dlg = app.inform (_("Error"), e.message);
				dlg.present ();
			} finally {
				this.sensitive = true;
				on_close ();
			}
		});
	}

	void on_bio_emoji_picked (string emoji_unicode) {
		bio_text_view.buffer.insert_at_cursor (emoji_unicode, emoji_unicode.data.length);
	}

	bool has_error (Gtk.Widget wdg) {
		return wdg.has_css_class ("error");
	}

	void on_name_row_changed () {
		var valid = name_row.text.length <= 30;
		Tuba.toggle_css (name_row, !valid, "error");
	}

	void on_bio_text_changed () {
		var valid = bio_text_view.buffer.get_char_count () <= 500;
		Tuba.toggle_css (bio_row, !valid, "error");
	}

	private API.Account profile { get; set; }
	Gee.ArrayList<Field> fields = new Gee.ArrayList<Field> ();
	int64 max_fields;
	int64 max_key_length;
	int64 max_value_length;
	public ProfileEdit (API.Account acc) {
		profile = acc;
		image_cache.request_paintable (acc.header, on_cache_response);
		avi.url = acc.avatar;
		avi.text = acc.display_name;
		name_row.text = acc.display_name;
		bio_text_view.buffer.text = acc.source?.note ?? "";

		max_fields = accounts.active.instance_info.compat_fields_limits_max_fields;
		max_key_length = accounts.active.instance_info.compat_fields_limits_name_length;
		max_value_length = accounts.active.instance_info.compat_fields_limits_value_length;

		// Add known fields
		if (acc?.source?.fields?.size > 0) {
			for (var i = 0; i < acc.source.fields.size; i++) {
				var field = acc.source.fields.get (i);
				add_field (field.name, field.val);
			}
		}

		var fields_left = max_fields - (acc?.source?.fields?.size ?? 0);
		if (fields_left > 0) {
			for (var i = 0; i < fields_left; i++) {
				add_field (null, null);
			}
		}
	}

	private void add_field (string? key, string? value) {
		var field = new Field (key, value, max_key_length, max_value_length);
		field.title = _("Field %d").printf (fields.size + 1);

		fields.add (field);
		fields_box.add (field);
	}

	void on_cache_response (bool is_loaded, owned Gdk.Paintable? data) {
		background.paintable = data;
	}

	File new_avi;
	File new_header;
	void choose_file (bool for_header = false) {
		#if GTK_4_10
			var chooser = new Gtk.FileDialog () {
				title = _("Open"),
				modal = true,
				default_filter = filter
			};
			chooser.open.begin (this, null, (obj, res) => {
				try {
				var file = chooser.open.end (res);
		#else
			var chooser = new Gtk.FileChooserNative (_("Open"), this, Gtk.FileChooserAction.OPEN, null, null) {
				select_multiple = false,
				filter = filter
			};

			chooser.response.connect (id => {
				switch (id) {
					case ResponseType.ACCEPT:
						var file = chooser.get_file ();
		#endif

				try {
					var texture = Gdk.Texture.from_file (file);

					if (for_header) {
						new_header = file;
						background.paintable = texture;
					} else {
						new_avi = file;
						avi.custom_image = texture;
					}

				} catch (Error e) {
					critical (@"Couldn't construct Texture from file $(e.message)");
				}

		#if GTK_4_10
				} catch (Error e) {
					// User dismissing the dialog also ends here so don't make it sound like
					// it's an error
					warning (@"Couldn't get the result of FileDialog for ProfileEdit: $(e.message)");
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

	public signal void saved ();
	async void save () throws Error {
		var req = new Request.PATCH ("/api/v1/accounts/update_credentials")
					.with_account (accounts.active);

		if (!has_error (name_row) && profile.display_name != name_row.text)
			req.with_form_data ("display_name", name_row.text);

		if (!has_error (bio_row) && profile.source?.note != bio_text_view.buffer.text)
			req.with_form_data ("note", bio_text_view.buffer.text);


		var i = 0;
		foreach (var field in fields) {
			req.with_form_data (@"fields_attributes[$i][name]", field.valid ? field.key : "");
			req.with_form_data (@"fields_attributes[$i][value]", field.valid ? field.value : "");
			i++;
		}

		if (new_avi != null) {
			string mime;
			Bytes buffer;
			image_data (new_avi, out mime, out buffer);

			req.with_form_data_file ("avatar", mime, buffer);
		}

		if (new_header != null) {
			string mime;
			Bytes buffer;
			image_data (new_header, out mime, out buffer);

			req.with_form_data_file ("header", mime, buffer);
		}

		yield req.await ();

		accounts.active.update_object (req.response_body);
		saved ();
	}

	void image_data (File file, out string mime, out Bytes buffer) throws Error {
		uint8[] t_contents;
		string t_mime ="";
		try {
			file.load_contents (null, out t_contents, null);
			GLib.FileInfo type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
			t_mime = type.get_content_type ();
		} catch (Error e) {
			throw new Oopsie.USER ("Can't open file %s:\n%s".printf (file.get_path (), e.message));
		}

		buffer = new Bytes.take (t_contents);
		mime = t_mime;
	}
}
