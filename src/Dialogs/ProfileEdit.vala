[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/dialogs/profile_edit.ui")]
public class Tuba.Dialogs.ProfileEdit : Adw.Dialog {
	~ProfileEdit () {
		debug (@"Destroying ProfileEdit for $(profile.handle)");
	}

	public class Field : Adw.ExpanderRow {
		~Field () {
			debug ("Destroying ProfileEdit.Field");
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
				// tanslators: profile field label or title
				title = _("Label"),
				text = t_key ?? ""
			};
			key_row.changed.connect (update_valid_style);

			value_row = new Adw.EntryRow () {
				input_purpose = Gtk.InputPurpose.FREE_FORM,
				// translators: profile field content
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

	[GtkChild] unowned Adw.EntryRow name_row;
	[GtkChild] unowned Adw.ExpanderRow bio_row;
	[GtkChild] unowned GtkSource.View bio_text_view;
	[GtkChild] unowned Adw.Avatar avi;
	[GtkChild] unowned Gtk.Picture background;
	[GtkChild] unowned Adw.PreferencesGroup fields_box;
	[GtkChild] unowned Gtk.MenuButton cepbtn;

	Gtk.FileFilter filter = new Gtk.FileFilter () {
		name = _("All Supported Files")
	};

	construct {
		filter.add_mime_type ("image/jpeg");
		filter.add_mime_type ("image/png");
		filter.add_mime_type ("image/gif");

		bio_text_view.remove_css_class ("view");
		bio_text_view.buffer.changed.connect (on_bio_text_changed);
		Adw.StyleManager.get_default ().notify["dark"].connect (update_style_scheme);
		update_style_scheme ();

		#if LIBSPELLING
			var adapter = new Spelling.TextBufferAdapter ((GtkSource.Buffer) bio_text_view.buffer, Spelling.Checker.get_default ());

			bio_text_view.extra_menu = adapter.get_menu_model ();
			bio_text_view.insert_action_group ("spelling", adapter);
			adapter.enabled = true;
		#endif

		if (accounts.active.instance_emojis != null && accounts.active.instance_emojis.size > 0) {
			cepbtn.visible = true;
		}
	}

	protected void update_style_scheme () {
		var manager = GtkSource.StyleSchemeManager.get_default ();
		string scheme_name = "Adwaita";
		if (Adw.StyleManager.get_default ().dark) scheme_name += "-dark";
		((GtkSource.Buffer) bio_text_view.buffer).style_scheme = manager.get_scheme (scheme_name);
	}

	[GtkCallback]
	void on_close () {
		force_close ();
	}

	[GtkCallback]
	void on_avi_button_clicked () {
		choose_file (false);
	}

	[GtkCallback]
	void on_header_button_clicked () {
		choose_file (true);
	}

	[GtkCallback]
	void on_save_clicked () {
		this.sensitive = false;
		save.begin ((obj, res) => {
			try {
				save.end (res);
				on_close ();
			} catch (GLib.Error e) {
				critical (e.message);
				var dlg = app.inform (_("Error"), e.message);
				dlg.present (this);
			} finally {
				this.sensitive = true;
			}
		});
	}

	[GtkCallback]
	void on_bio_emoji_picked (string emoji_unicode) {
		bio_text_view.buffer.insert_at_cursor (emoji_unicode, emoji_unicode.data.length);
	}

	bool has_error (Gtk.Widget wdg) {
		return wdg.has_css_class ("error");
	}

	[GtkCallback]
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
		Tuba.Helper.Image.request_paintable (acc.header, null, on_background_cache_response);
		Tuba.Helper.Image.request_paintable (acc.avatar, null, on_avi_cache_response);
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
		// translators: profile field, the variable is a number, if unsure take a look at Mastodon https://github.com/mastodon/mastodon/blob/main/config/locales/ (under simple_form)
		field.title = _("Field %d").printf (fields.size + 1);

		fields.add (field);
		fields_box.add (field);
	}

	void on_background_cache_response (Gdk.Paintable? data) {
		background.paintable = data;
	}

	void on_avi_cache_response (Gdk.Paintable? data) {
		avi.custom_image = data;
	}

	File new_avi;
	File new_header;
	void choose_file (bool for_header = false) {
			var chooser = new Gtk.FileDialog () {
				title = _("Open"),
				modal = true,
				default_filter = filter
			};
			chooser.open.begin (app.main_window, null, (obj, res) => {
				try {
					var file = chooser.open.end (res);

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

				} catch (Error e) {
					// User dismissing the dialog also ends here so don't make it sound like
					// it's an error
					warning (@"Couldn't get the result of FileDialog for ProfileEdit: $(e.message)");
				}
			});
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
