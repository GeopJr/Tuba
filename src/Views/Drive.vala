public class Tuba.Views.Drive : Views.Base {
	public class Item : GLib.Object {
		public API.Iceshrimp.Folder? folder { get; set; default=null; }
		public API.Iceshrimp.File? file { get; set; default=null; }

		public bool can_delete (out string? reason = null) {
			bool res = false;
			reason = null;

			if (this.folder != null) {
				res = (this.folder.files == null || this.folder.files.size == 0)
					&& (this.folder.folders == null || this.folder.folders.size == 0);

				// translators: Error reason when trying to delete a non-empty folder
				if (!res) reason = _("Folder is not empty");
			} else if (this.file != null) {
				res = !this.file.isAvatar && !this.file.isBanner;

				// translators: Error reason when trying to delete an actively used file
				if (!res) reason = this.file.isAvatar ? _("File is used as an avatar") : _("File is used as a banner");
			}

			return res;
		}

		public Item.from_folder (API.Iceshrimp.Folder folder) {
			this.folder = folder;
		}

		public Item.from_file (API.Iceshrimp.File file) {
			this.file = file;
		}
	}

	public class ItemWidget : Gtk.Box {
		~ItemWidget () {
			context_menu.unparent ();
			context_menu = null;

			if (rename_popover != null) {
				rename_popover.unparent ();
				rename_popover = null;
			}

			if (alt_popover != null) {
				alt_popover.unparent ();
				alt_popover = null;
			}
		}

		public signal void refresh ();
		public signal void delete_me ();
		public signal void open_me (Item? item);
		public signal void fill_reserved_names (EntryPopover popover);
		public signal void pressed (bool not_pressing);
		public signal void move (string to_folder, Item? grabbed_item);

		public bool folder {
			get { return item == null ? false : item.folder != null; }
		}

		public string filename {
			get { return item == null ? "" : (this.folder ? item.folder.name : item.file.filename); }
			set { label.label = label.tooltip_text = value; }
		}

		public string item_id {
			get { return item == null ? "" : (this.folder ? item.folder.id : item.file.id); }
		}

		ulong last_style_manager_notify = 0;
		private unowned Item? _item = null;
		public Item? item {
			get { return _item; }
			private set {
				_item = value;

				if (_item.folder != null) {
					if (last_style_manager_notify == 0) {
						last_style_manager_notify = (Adw.StyleManager.get_default ()).notify["accent-color-rgba"].connect (update_folder_color);
						update_folder_color ();
					}
				} else {
					if (_item.file.contentType.has_prefix ("image/") || _item.file.contentType.has_prefix ("audio/"))
						Helper.Image.request_paintable (_item.file.thumbnailUrl.replace ("https://shrimp.example.org", accounts.active.instance), null, false, on_thumbnail_loaded);
				}

				this.filename = this.filename;
				update_actions ();
				update_indicators ();
				update_drop_target ();
			}
		}

		private void update_indicators () {
			if (this.folder || this.item == null) {
				indicator_alt.visible =
				indicator_avi.visible =
				indicator_sensitive.visible = false;
			} else {
				indicator_alt.visible = this.item.file.description != null && this.item.file.description != "";
				indicator_avi.visible = this.item.file.isAvatar || this.item.file.isBanner;
				indicator_sensitive.visible = this.item.file.sensitive;
			}

			indicator_box.visible = indicator_alt.visible || indicator_avi.visible || indicator_sensitive.visible;
		}

		private void update_drop_target (bool dragging = false) {
			if (this.folder && !dragging) {
				drop_target_controller.set_gtypes ({typeof (Views.Drive.Item?)});
			} else {
				drop_target_controller.set_gtypes (null);
			}
		}

		static construct {
			set_css_name ("drive-item");
		}

		Gtk.Image image;
		Gtk.Label label;
		Gtk.PopoverMenu context_menu;
		Gtk.GestureClick gesture_click_controller_grab;
		Gtk.GestureClick gesture_click_controller;
		Gtk.GestureLongPress gesture_lp_controller;
		EntryPopover? rename_popover = null;
		EntryPopover? alt_popover = null;
		SimpleAction[] file_only_actions;
		SimpleAction ms_action;
		SimpleAction delete_action;
		Gtk.Image indicator_alt;
		Gtk.Image indicator_avi;
		Gtk.Image indicator_sensitive;
		Gtk.Box indicator_box;
		Gtk.DropTarget drop_target_controller;
		construct {
			this.orientation = Gtk.Orientation.VERTICAL;
			this.spacing = 6;
			this.margin_start = this.margin_end = 9;

			image = new Gtk.Image.from_icon_name ("tuba-paper-symbolic") {
				icon_size = Gtk.IconSize.LARGE,
				height_request =
				width_request = 96
			};
			label = new Gtk.Label ("") {
				ellipsize = Pango.EllipsizeMode.MIDDLE
			};

			indicator_box = new Gtk.Box (HORIZONTAL, 6) {
				halign = END,
				valign = START,
				margin_top = 6,
				can_focus = false,
				focusable = false,
				css_classes = { "osd", "indicator-box" },
				visible = false
			};

			indicator_alt = new Gtk.Image.from_icon_name ("document-edit-symbolic") {
				valign = CENTER,
				halign = CENTER,
				tooltip_text = _("Alternative Text"),
				visible = false
			};
			indicator_box.append (indicator_alt);

			indicator_avi = new Gtk.Image.from_icon_name ("tuba-person-symbolic") {
				valign = CENTER,
				halign = CENTER,
				// translators: tooltip text on an icon that indicates that a file is used
				//				by a user profile (like an avatar)
				tooltip_text = _("Used by a Profile"),
				visible = false
			};
			indicator_box.append (indicator_avi);

			indicator_sensitive = new Gtk.Image.from_icon_name ("tuba-eye-not-looking-symbolic") {
				valign = CENTER,
				halign = CENTER,
				tooltip_text = _("Sensitive"),
				visible = false
			};
			indicator_box.append (indicator_sensitive);

			var overlay = new Gtk.Overlay () {
				child = image
			};
			overlay.add_overlay (indicator_box);

			this.append (overlay);
			this.append (label);

			var open_action = new SimpleAction ("open", null);
			var copy_link_action = new SimpleAction ("copy-link", null);
			ms_action = new SimpleAction.stateful ("mark-as-sensitive", null, false);
			var alt_action = new SimpleAction ("set-alt-text", null);
			var rename_action = new SimpleAction ("rename", null);
			delete_action = new SimpleAction ("delete", null);
			open_action.activate.connect (on_open);
			copy_link_action.activate.connect (on_copy);
			ms_action.change_state.connect (on_ms_change);
			alt_action.activate.connect (on_alt_text);
			rename_action.activate.connect (on_rename);
			delete_action.activate.connect (on_delete);

			file_only_actions = {
				copy_link_action,
				ms_action,
				alt_action
			};

			var action_group = new GLib.SimpleActionGroup ();
			action_group.add_action (open_action);
			action_group.add_action (copy_link_action);
			action_group.add_action (ms_action);
			action_group.add_action (alt_action);
			action_group.add_action (rename_action);
			action_group.add_action (delete_action);

			this.insert_action_group ("driveitem", action_group);

			var menu_model = new GLib.Menu ();
			var open_menu = new GLib.Menu ();
			open_menu.append (_("Open"), "driveitem.open");

			var copy_link_menu_item = new MenuItem (_("Copy Link"), "driveitem.copy-link");
			copy_link_menu_item.set_attribute_value ("hidden-when", "action-disabled");
			open_menu.append_item (copy_link_menu_item);
			menu_model.append_section (null, open_menu);

			var file_menu = new GLib.Menu ();
			var ms_menu_item = new MenuItem (_("Mark as Sensitive"), "driveitem.mark-as-sensitive");
			ms_menu_item.set_attribute_value ("hidden-when", "action-disabled");
			file_menu.append_item (ms_menu_item);

			var alt_menu_item = new MenuItem (_("Edit Alt Text"), "driveitem.set-alt-text");
			alt_menu_item.set_attribute_value ("hidden-when", "action-disabled");
			file_menu.append_item (alt_menu_item);
			menu_model.append_section (null, file_menu);

			var item_menu = new GLib.Menu ();
			item_menu.append (_("Rename"), "driveitem.rename");
			item_menu.append (_("Delete"), "driveitem.delete");
			menu_model.append_section (null, item_menu);

			context_menu = new Gtk.PopoverMenu.from_model (menu_model) {
				has_arrow = false,
				halign = Gtk.Align.START
			};
			context_menu.set_parent (this);

			gesture_click_controller_grab = new Gtk.GestureClick () {
				button = Gdk.BUTTON_PRIMARY
			};
			gesture_click_controller = new Gtk.GestureClick () {
				button = Gdk.BUTTON_SECONDARY
			};
			gesture_lp_controller = new Gtk.GestureLongPress () {
				button = Gdk.BUTTON_PRIMARY,
				touch_only = true
			};
			add_controller (gesture_click_controller_grab);
			add_controller (gesture_click_controller);
			add_controller (gesture_lp_controller);
			gesture_click_controller_grab.pressed.connect (on_primary_click_pressed);
			gesture_click_controller_grab.released.connect (on_primary_click_released);
			gesture_click_controller_grab.stopped.connect (on_primary_click_released);
			gesture_click_controller.pressed.connect (on_secondary_click);
			gesture_lp_controller.pressed.connect (on_long_press);

			var drag_source_controller = new Gtk.DragSource () {
				actions = MOVE
			};
			drag_source_controller.prepare.connect (on_drag_prepare);
			drag_source_controller.drag_begin.connect (on_drag_begin);
			drag_source_controller.drag_end.connect (on_drag_end);
			drag_source_controller.drag_cancel.connect (on_drag_cancel);
			this.add_controller (drag_source_controller);

			drop_target_controller = new Gtk.DropTarget (typeof (Views.Drive.Item?), MOVE);
			drop_target_controller.drop.connect (on_drop);
			this.add_controller (drop_target_controller);
		}

		private bool on_drop (Gtk.DropTarget dt_controller, GLib.Value value, double x, double y) {
			if (!this.folder || this.item == null || dt_controller.get_value () == null) return false;
			move (this.item_id, (Views.Drive.Item?) dt_controller.get_value ());
			return true;
		}

		double drag_x = 0;
		double drag_y = 0;
		private Gdk.ContentProvider? on_drag_prepare (double x, double y) {
			if (this.item == null) return null;
			pressed (false);

			drag_x = x;
			drag_y = y;

			return new Gdk.ContentProvider.for_value (this.item); // TODO leak test...
		}

		private void on_drag_begin (Gtk.DragSource ds_controller, Gdk.Drag drag) {
			ds_controller.set_icon ((new Gtk.WidgetPaintable (this)).get_current_image (), (int) drag_x, (int) drag_y);
			update_drop_target (true);
		}

		private void on_drag_end (Gdk.Drag drag, bool delete_data) {
			pressed (true);
			update_drop_target (false);
		}

		private bool on_drag_cancel (Gdk.Drag drag, Gdk.DragCancelReason reason) {
			pressed (true);
			update_drop_target (false);
			return false;
		}

		private void update_actions () {
			if (item != null) {
				delete_action.set_enabled (item.can_delete ());
				if (item.file != null) ms_action.set_state (item.file.sensitive);
			}

			foreach (var action in file_only_actions) {
				action.set_enabled (!folder);
			}
		}

		private void on_ms_change (GLib.Variant? variant) {
			if (variant == null || this.folder) return;

			var builder = new Json.Builder ();
			builder.begin_object ();
			builder.set_member_name ("description");
			builder.add_null_value ();
			builder.set_member_name ("filename");
			builder.add_null_value ();
			builder.set_member_name ("sensitive");
			builder.add_boolean_value (!this.item.file.sensitive);
			builder.end_object ();

			new Request.PATCH (@"/api/iceshrimp/drive/$(this.item_id)")
				.with_account (accounts.active)
				.with_token (accounts.active.tuba_iceshrimp_api_key)
				.body_json (builder)
				.then (() => {
					ms_action.set_state (!this.item.file.sensitive);
					this.item.file.sensitive = !this.item.file.sensitive;
					update_indicators ();
				})
				.on_error ((code, message) => {
					// translators: the first variable is a filename,
					//				the second is an error message
					app.toast (_("Couldn't mark '%s' as sensitive: %s").printf (GLib.Markup.escape_text (this.filename), message));
					warning (@"Couldn't mark $(this.folder ? "folder" : "file") '$(this.filename)' as sensitive: $code $message");
				})
				.exec ();
		}

		private void on_copy () {
			if (this.folder || this.item == null) return;

			Utils.Host.copy (this.item.file.url);
		}

		private void on_open () {
			open_me (this.item);
		}

		private void on_delete () {
			delete_me ();
		}

		private void on_rename () {
			if (rename_popover != null) {
				rename_popover.unparent ();
				rename_popover = null;
			}

			rename_popover = new EntryPopover (
				this.folder ? _("Rename Folder") : _("Rename File"),
				this.filename,
				_("Rename"),
				null
			);
			fill_reserved_names (rename_popover);
			rename_popover.set_parent (this);
			rename_popover.text = this.filename;
			rename_popover.done.connect (on_rename_real);
			rename_popover.popup ();
		}

		private void on_alt_text () {
			if (this.folder || this.item == null) return;

			if (alt_popover == null) {
				alt_popover = new EntryPopover (
					_("Alternative Text"),
					this.item.file.description == null ? "" : this.item.file.description,
					_("Save"),
					null,
					true
				);
				alt_popover.set_parent (this);
			} else {
				alt_popover.text = this.item.file.description == null ? "" : this.item.file.description;
			}

			alt_popover.done.connect (on_alt_real);
			alt_popover.popup ();
		}

		private void on_alt_real (string new_alt) {
			var builder = new Json.Builder ();
			builder.begin_object ();
			builder.set_member_name ("filename");
			builder.add_null_value ();
			builder.set_member_name ("sensitive");
			builder.add_null_value ();
			builder.set_member_name ("description");
			builder.add_string_value (new_alt);
			builder.end_object ();

			new Request.PATCH (@"/api/iceshrimp/drive/$(this.item_id)")
				.body_json (builder)
				.with_account (accounts.active)
				.with_token (accounts.active.tuba_iceshrimp_api_key)
				.then (() => {
					this.item.file.description = new_alt;
					update_indicators ();
				})
				.on_error ((code, message) => {
					// translators: the first variable is a filename,
					//				the second is an error message
					app.toast (_("Couldn't change alt text for '%s': %s").printf (GLib.Markup.escape_text (this.filename), message));
					warning (@"Couldn't change alt for '$(this.filename)' to '$new_alt': $code $message");
				})
				.exec ();
		}

		private void on_rename_real (string new_name) {
			Request req;
			if (this.folder) {
				Json.Node node = new Json.Node (Json.NodeType.VALUE);
				node.set_string (new_name);
				Json.Generator gen = new Json.Generator ();
				gen.set_root (node);
				req = new Request.PUT (@"/api/iceshrimp/drive/folder/$(this.item_id)")
					.body ("application/json", new Bytes.take (gen.to_data (null).data));
			} else {
				var builder = new Json.Builder ();
				builder.begin_object ();
				builder.set_member_name ("description");
				builder.add_null_value ();
				builder.set_member_name ("sensitive");
				builder.add_null_value ();
				builder.set_member_name ("filename");
				builder.add_string_value (new_name);
				builder.end_object ();

				req = new Request.PATCH (@"/api/iceshrimp/drive/$(this.item_id)")
					.body_json (builder);
			}

			req
				.with_account (accounts.active)
				.with_token (accounts.active.tuba_iceshrimp_api_key)
				.then (() => {
					this.filename = new_name;
					if (this.folder) {
						item.folder.name = new_name;
					} else {
						item.file.filename = new_name;
					}
				})
				.on_error ((code, message) => {
					// translators: the first variable is a filename,
					//				the second is an error message
					app.toast (_("Couldn't rename '%s': %s").printf (GLib.Markup.escape_text (this.filename), message));
					warning (@"Couldn't rename $(this.folder ? "folder" : "file") '$(this.filename)' to '$new_name': $code $message");
				})
				.exec ();
		}

		private void on_long_press (double x, double y) {
			on_secondary_click (1, x, y);
		}

		private void on_secondary_click (int n_press, double x, double y) {
			gesture_click_controller.set_state (Gtk.EventSequenceState.CLAIMED);
			gesture_lp_controller.set_state (Gtk.EventSequenceState.CLAIMED);

			if (app.main_window.is_media_viewer_visible) return;
			Gdk.Rectangle rectangle = {
				(int) x,
				(int) y,
				0,
				0
			};
			context_menu.set_pointing_to (rectangle);
			context_menu.popup ();
		}

		private void on_primary_click_pressed () {
			pressed (false);
		}

		private void on_primary_click_released () {
			pressed (true);
		}

		public void populate (Item item) {
			this.item = item;
		}

		protected void update_folder_color () {
			var adw_manager = Adw.StyleManager.get_default ();

			string color = "blue";
			if (adw_manager.get_system_supports_accent_colors ()) {
				switch (adw_manager.get_accent_color ()) {
					case Adw.AccentColor.YELLOW:
						color = "yellow";
						break;
					case Adw.AccentColor.TEAL:
						color = "teal";
						break;
					case Adw.AccentColor.PURPLE:
						color = "purple";
						break;
					case Adw.AccentColor.RED:
						color = "red";
						break;
					case Adw.AccentColor.GREEN:
						color = "green";
						break;
					case Adw.AccentColor.ORANGE:
						color = "orange";
						break;
					case Adw.AccentColor.SLATE:
						color = "slate";
						break;
					case Adw.AccentColor.PINK:
						color = "pink";
						break;
					default:
						break;
				}
			}

			image.resource = @"/dev/geopjr/Tuba/icons/folders/$color.svg";
		}

		private void on_thumbnail_loaded (Gdk.Paintable? data) {
			if (data != null) image.paintable = data;
		}
	}

	public class EntryPopover : Gtk.Popover {
		public signal void done (string result);

		Gtk.Label title;
		Gtk.Entry entry;
		Gtk.Button action;
		string[] taken_names = {};
		bool can_be_empty = false;
		construct {
			var box = new Gtk.Box (VERTICAL, 12) {
				width_request = 200,
				margin_bottom = margin_end = margin_start = margin_top = 12
			};
			title = new Gtk.Label ("") {
				css_classes = { "title-2" },
				hexpand = true
			};
			box.append (title);

			entry = new Gtk.Entry () { hexpand = true };
			entry.activate.connect (on_action);
			entry.buffer.notify["text"].connect (validate);
			box.append (entry);

			action = new Gtk.Button () {
				vexpand = false,
				halign = END,
				css_classes = {"suggested-action"}
			};
			action.clicked.connect (on_action);
			box.append (action);

			this.child = box;
			this.default_widget = entry;
		}

		public EntryPopover (string title_label, string placeholder, string button_label, string[]? taken_names = null, bool empty_allowed = false) {
			title.label = title_label;
			entry.placeholder_text = placeholder;
			action.label = button_label;
			if (taken_names != null) this.taken_names = taken_names;
			this.can_be_empty = empty_allowed;
		}

		public void clear () {
			entry.buffer.set_text ("".data);
		}

		public string text {
			get { return entry.buffer.text; }
			set { entry.buffer.set_text (value.data); }
		}

		public void update_taken_names (string[]? taken_names = null) {
			if (taken_names == null) {
				this.taken_names = {};
				return;
			}

			this.taken_names = taken_names;
		}

		private void on_action () {
			if (!action.sensitive) return;

			done (entry.buffer.text.strip ());
			this.popdown ();
		}

		private void validate () {
			string stripped_text = entry.text.strip ();
			bool invalid = (!this.can_be_empty && stripped_text == "") || stripped_text.down () in taken_names;
			action.sensitive = !invalid;

			if (invalid) {
				entry.add_css_class ("error");
			} else {
				entry.remove_css_class ("error");
			}
		}
	}

	private Gtk.Button go_back_btn;
	private Gtk.MenuButton create_folder_btn;
	private Gtk.Button upload_file_btn;
	private EntryPopover create_folder_btn_popover;
	protected override void build_header () {
		base.build_header ();

		go_back_btn = new Gtk.Button () {
			icon_name = "go-previous-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("Go Back"),
			visible = false
		};
		go_back_btn.clicked.connect (on_go_back);
		header.pack_start (go_back_btn);

		var back_drop_target_controller = new Gtk.DropTarget (typeof (Views.Drive.Item?), MOVE);
		back_drop_target_controller.drop.connect (on_back_drop);
		go_back_btn.add_controller (back_drop_target_controller);

		create_folder_btn_popover = new EntryPopover (_("New Folder"), _("Folder Name"), _("Create"));
		create_folder_btn_popover.done.connect (on_create_folder_done);
		create_folder_btn = new Gtk.MenuButton () {
			icon_name = "tuba-folder-new-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("Create Folder"),
			always_show_arrow = false,
			popover = create_folder_btn_popover
		};

		upload_file_btn = new Gtk.Button () {
			icon_name = "tuba-plus-large-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("Upload File")
		};
		upload_file_btn.clicked.connect (upload_pick);

		header.pack_end (upload_file_btn);
		header.pack_end (create_folder_btn);
	}

	private bool on_back_drop (Gtk.DropTarget dt_controller, GLib.Value value, double x, double y) {
		if (this.current_folder == null || dt_controller.get_value () == null) return false;

		move_items (this.current_folder.parentId, (Views.Drive.Item?) dt_controller.get_value ());
		return true;
	}

	private void on_create_folder_done (EntryPopover popover, string name) {
		create_folder_real.begin (name, (obj, res) => {
			if (create_folder_real.end (res)) {
				popover.clear ();
			}
		});
	}

	private async bool create_folder_real (string name) {
		var builder = new Json.Builder ();
		builder.begin_object ();

		builder.set_member_name ("name");
		builder.add_string_value (name);

		builder.set_member_name ("parentId");
		if (this.current_folder == null || this.current_folder.id == null || this.current_folder.id == "") {
			builder.add_null_value ();
		} else {
			builder.add_string_value (this.current_folder.id);
		}

		builder.end_object ();

		var req = new Request.POST ("/api/iceshrimp/drive/folder")
			.with_account (accounts.active)
			.with_token (accounts.active.tuba_iceshrimp_api_key)
			.body_json (builder);

		base_status = new StatusMessage () { loading = true };
		try {
			yield req.await ();

			var parser = Network.get_parser_from_inputstream (req.response_body);
			var node = network.parse_node (parser);
			var entity = Helper.Entity.from_json (node, typeof (API.Iceshrimp.Folder));
			if (entity is API.Iceshrimp.Folder) {
				if (this.current_folder.folders == null) {
					this.current_folder.folders = new Gee.ArrayList<API.Iceshrimp.Folder> ();
				}

				this.current_folder.folders.insert (0, (API.Iceshrimp.Folder) entity);
				store.splice (0, 0, {new Item.from_folder ((API.Iceshrimp.Folder) entity)});
			}
		} catch (Error e) {
			base_status = null;
			// translators: error that shows up as a toast when creating folders
			//				in iceshrimp drive
			app.toast (_("Couldn't create folder: %s").printf (e.message));
			warning (@"Couldn't create folder: $(e.code) $(e.message)");

			return false;
		}

		base_status = null;
		return true;
	}

	private void on_go_back () {
		load_folder (this.current_folder == null ? null : this.current_folder.parentId);
	}

	API.Iceshrimp.Folder? current_folder { get; set; default = null; }

	Gtk.GridView grid;
	Gtk.MultiSelection selection;
	GLib.ListStore store;
	construct {
		this.icon = "tuba-folder-visiting-symbolic";
		this.label = _("Drive");

		Gtk.SignalListItemFactory signallistitemfactory = new Gtk.SignalListItemFactory ();
		signallistitemfactory.setup.connect (setup_listitem_cb);
		signallistitemfactory.bind.connect (bind_listitem_cb);

		store = new GLib.ListStore (typeof (Item));
		store.items_changed.connect (on_store_changed);
		selection = new Gtk.MultiSelection (store);
		grid = new Gtk.GridView (selection, signallistitemfactory) {
			enable_rubberband = true,
			single_click_activate = false,
			overflow = VISIBLE
		};
		grid.activate.connect (on_item_activated);
		grid.remove_css_class ("view");

		// Replacing the widget is messy with Base
		// so let's just replace the page
		states.get_page (scrolled).name = "old-content";
		states.add_named (new Gtk.ScrolledWindow () {
			vexpand = true,
			child = new Adw.ClampScrollable () {
				vexpand = true,
				maximum_size = 670,
				tightening_threshold = 670,
				child = grid,
				css_classes = { "ttl-view" },
				overflow = HIDDEN
			}
		}, "content");

		var primary_click = new Gtk.GestureClick () {
			button = Gdk.BUTTON_PRIMARY
		};
		primary_click.pressed.connect (on_primary_click);
		grid.add_controller (primary_click);

		if (accounts.active.tuba_iceshrimp_api_key == null || accounts.active.tuba_iceshrimp_api_key == "") {
			base_status = new StatusMessage () { loading = true };
			new Request.POST ("/api/v1/accounts/authorize_iceshrimp")
				.with_account (accounts.active)
				.then ((in_stream) => {
					var parser = Network.get_parser_from_inputstream (in_stream);
					var node = network.parse_node (parser);
					if (node == null) throw new Oopsie.PARSING ("Instance didn't return key");
					string key = node.get_string ();
					if (key == null || key == "") throw new Oopsie.PARSING ("Instance key is missing");
					accounts.active.tuba_update_iceshrimp_api_key (key);

					load_folder ();
				})
				.on_error (on_error)
				.exec ();
		} else {
			load_folder ();
		}
	}

	private void on_primary_click (Gtk.GestureClick gesture, int n_press, double x, double y) {
		if (n_press == 1 && grid.enable_rubberband) {
			grid.grab_focus ();
			var modifier = gesture.get_current_event_state () & Gdk.MODIFIER_MASK;
			if (modifier != Gdk.ModifierType.CONTROL_MASK && modifier != Gdk.ModifierType.SHIFT_MASK && selection.get_n_items () > 0)
				selection.unselect_all ();
		}
	}

	private void load_folder (string? id = null) {
		base_status = new StatusMessage () { loading = true };
		var folder_id = id == null ? "" : @"/$id";
		new Request.GET (@"/api/iceshrimp/drive/folder$folder_id")
			.with_account (accounts.active)
			.with_token (accounts.active.tuba_iceshrimp_api_key)
			.then ((in_stream) => {
				var parser = Network.get_parser_from_inputstream (in_stream);
				var node = network.parse_node (parser);
				this.current_folder = API.Iceshrimp.Folder.from (node);
				this.label = current_folder.name != null ? current_folder.name : _("Drive");
				open_folder (current_folder);
				if (create_folder_btn_popover != null) {
					create_folder_btn_popover.clear ();
				}
			})
			.on_error (on_error)
			.exec ();
	}

	private void on_store_changed () {
		if (create_folder_btn_popover != null) create_folder_btn_popover.update_taken_names (reserved_names ());
	}

	private string[] reserved_names () {
		string[] result = {};

		if (this.current_folder.folders != null) {
			foreach (var folder in this.current_folder.folders) {
				string folder_name_down = folder.name.down ();
				if (!(folder_name_down in result)) result += folder_name_down;
			}
		}

		if (this.current_folder.files != null) {
			foreach (var file in this.current_folder.files) {
				string file_name_down = file.filename.down ();
				if (!(file_name_down in result)) result += file_name_down;
			}
		}

		return result;
	}

	private void open_folder (API.Iceshrimp.Folder folder) {
		base_status = null;

		Item[] items = {};
		foreach (API.Iceshrimp.Folder subfold in folder.folders) {
			items += new Item.from_folder (subfold);
		}
		foreach (API.Iceshrimp.File subfile in folder.files) {
			items += new Item.from_file (subfile);
		}
		store.splice (0, store.n_items, items);

		go_back_btn.visible = folder.id != null;
	}

	private void setup_listitem_cb (GLib.Object obj) {
		Gtk.ListItem list_item = (Gtk.ListItem) obj;
		var item_widget = new ItemWidget ();
		item_widget.fill_reserved_names.connect (fill_reserved_names);
		item_widget.open_me.connect (on_open_request);
		item_widget.delete_me.connect (on_delete_request);
		item_widget.refresh.connect (on_refresh);
		item_widget.pressed.connect (update_rubberband);
		item_widget.move.connect (move_items);
		list_item.set_child (item_widget);
	}

	private void on_refresh () {
		load_folder (this.current_folder.id);
	}

	private void bind_listitem_cb (GLib.Object item) {
		var drive_item = (Item) ((Gtk.ListItem) item).item;
		var widget = (ItemWidget) ((Gtk.ListItem) item).child;
		widget.populate (drive_item);

		var gtklistitemwidget = widget.get_parent ();
		if (gtklistitemwidget != null) {
			gtklistitemwidget.margin_start =
			gtklistitemwidget.margin_end =
			gtklistitemwidget.margin_top =
			gtklistitemwidget.margin_bottom = 3;
		}
	}

	private void on_item_activated (uint pos) {
		if (selection.get_selection ().get_size () != 1) return;

		var item = (Item) store.get_item (pos);
		open_item_real (item);
	}

	private void open_item_real (Item item) {
		if (item.folder != null) {
			load_folder (item.folder.id);
		} else if (item.file.contentType.has_prefix ("image/")) {
			app.main_window.show_media_viewer (item.file.url.replace ("https://shrimp.example.org", accounts.active.instance), Attachment.MediaType.IMAGE, null);
		} else if (item.file.contentType.has_prefix ("audio/")) {
			app.main_window.show_media_viewer (item.file.url.replace ("https://shrimp.example.org", accounts.active.instance), Attachment.MediaType.AUDIO, null, null, false, null, null, null, true);
		} else {
			Utils.Host.open_url.begin (item.file.url);
		}
	}

	private void fill_reserved_names (EntryPopover popover) {
		popover.update_taken_names (reserved_names ());
	}

	private void on_open_request (Item? item) {
		if (item != null) open_item_real (item);
	}

	private void update_rubberband (bool enable) {
		grid.enable_rubberband = enable;
	}

	struct ItemData {
		string id;
		string name;
		bool folder;
		Item item;
	}

	struct ReqData {
		Request req;
		ItemData item_data;
	}

	private void move_items (string? to_folder, Item? sample_item) {
		var bitset = selection.get_selection ();
		ItemData[] items = {};

		uint[] positions = {};
		uint val;
		Gtk.BitsetIter iter = Gtk.BitsetIter ();
		if (iter.init_first (bitset, out val)) {
			positions += val;
			while (iter.next (out val)) positions += val;
		}

		if (sample_item != null && (to_folder == null || (sample_item.folder != null ? sample_item.folder.id : sample_item.file.id) != to_folder)) {
			uint pos;
			if (store.find (sample_item, out pos)) {
				if (!(pos in positions)) positions += pos;
			}
		}

		foreach (uint pos in positions) {
			var sub_item = (Item) store.get_item (pos);
			if (sub_item.folder != null) {
				if (sub_item.folder.id != null && sub_item.folder.id != "" && (to_folder == null || sub_item.folder.id != to_folder)) {
					items += ItemData () {
						id = sub_item.folder.id,
						name = sub_item.folder.name,
						folder = true,
						item = sub_item
					};
				}
			} else {
				if (sub_item.file.id != null && sub_item.file.id != "") {
					items += ItemData () {
						id = sub_item.file.id,
						name = sub_item.file.filename,
						folder = false,
						item = sub_item
					};
				}
			}
		}

		move_items_real.begin (to_folder, items);
	}

	private async void move_items_real (string? to_folder, ItemData[] items) {
		bool requires_refresh = false;

		var builder = new Json.Builder ();
		builder.begin_object ();
		builder.set_member_name ("folderId");
		if (to_folder == null) {
			builder.add_null_value ();
		} else {
			builder.add_string_value (to_folder);
		}
		builder.end_object ();

		ReqData[] rqs = {};
		if (items.length > 0) {
			foreach (ItemData item_data in items) {
				rqs += ReqData () {
					req = new Request.POST (@"/api/iceshrimp/drive/$(item_data.folder ? "folder/" : "")$(item_data.id)/move")
						.with_account (accounts.active)
						.with_token (accounts.active.tuba_iceshrimp_api_key)
						.body_json (builder),
					item_data = item_data
				};
			}
		}

		foreach (ReqData rq in rqs) {
			try {
				yield rq.req.await ();

				uint pos;
				if (store.find (rq.item_data.item, out pos)) {
					store.remove (pos);
				} else {
					requires_refresh = true;
				}
			} catch (Error e) {
				app.toast (_("Couldn't move '%s': %s").printf (GLib.Markup.escape_text (rq.item_data.name), e.message));
				warning (@"Couldn't move item '$(rq.item_data.name)': $(e.code) $(e.message)");
			}
		}

		if (requires_refresh) on_refresh ();
	}

	private void on_delete_request (ItemWidget item) {
		var bitset = selection.get_selection ();
		var size = bitset.get_size ();
		if (size <= 1 && item.item_id != null) {
			string? error_reason = null;
			if (!item.item.can_delete (out error_reason)) {
				// translators: Error when trying to delete a file that cannot be deleted.
				//				The first variable is a string file name, the second is an error.
				string message = _("'%s' cannot be deleted: %s").printf (GLib.Markup.escape_text (item.filename), error_reason);
				app.toast (message);
				warning (message);
				return;
			}

			app.question.begin (
				// translators: the variable is a folder/file name
				{_("Delete '%s'?").printf (item.filename), false},
				{_("This is irreversible."), false},
				app.main_window,
				{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						new Request.DELETE (@"/api/iceshrimp/drive/$(item.folder ? "folder/" : "" )$(item.item_id)")
							.with_account (accounts.active)
							.with_token (accounts.active.tuba_iceshrimp_api_key)
							.then (() => {
								uint pos;
								if (store.find (item.item, out pos)) {
									store.remove (pos);
								} else {
									on_refresh ();
								}
							})
							.on_error ((code, message) => {
								// translators: the first variable is a filename,
								//				the second is an error message
								app.toast (_("Couldn't delete '%s': %s").printf (GLib.Markup.escape_text (item.filename), message));
								warning (@"Couldn't delete $(item.folder ? "folder" : "file") '$(item.filename)': $code $message");
							})
							.exec ();
					}
				}
			);
		} else if (size > 1) {
			ItemData[] items = {};

			uint[] positions = {};
			uint val;
			Gtk.BitsetIter iter = Gtk.BitsetIter ();
			if (iter.init_first (bitset, out val)) {
				positions += val;
				while (iter.next (out val)) positions += val;
			}

			foreach (uint pos in positions) {
				var sub_item = (Item) store.get_item (pos);
				if (!sub_item.can_delete ()) continue;

				if (sub_item.folder != null) {
					if (sub_item.folder.id != null && sub_item.folder.id != "") {
						items += ItemData () {
							id = sub_item.folder.id,
							name = sub_item.folder.name,
							folder = true,
							item = sub_item
						};
					}
				} else {
					if (sub_item.file.id != null && sub_item.file.id != "") {
						items += ItemData () {
							id = sub_item.file.id,
							name = sub_item.file.filename,
							folder = false,
							item = sub_item
						};
					}
				}
			}

			if (items.length == 0) {
				// translators: Error when trying to delete files/folders
				//				that cannot be deleted.
				app.toast (_("No Deletable Files in Selection"));
				return;
			}

			app.question.begin (
				// translators: confirmation dialog in a file-browser-like page
				{_("Delete Selection?"), false},
				{_("This is irreversible."), false},
				app.main_window,
				{ { _("Delete"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						delete_real_many.begin (items);
					}
				}
			);
		}
	}

	private async void delete_real_many (ItemData[] items) { // TODO: progress bar? Cancel?
		bool requires_refresh = false;

		ReqData[] rqs = {};
		if (items.length > 0) {
			foreach (ItemData item_data in items) {
				rqs += ReqData () {
					req = new Request.DELETE (@"/api/iceshrimp/drive/$(item_data.folder ? "folder/" : "")$(item_data.id)")
						.with_account (accounts.active)
						.with_token (accounts.active.tuba_iceshrimp_api_key),
					item_data = item_data
				};
			}
		}

		foreach (ReqData rq in rqs) {
			try {
				yield rq.req.await ();

				uint pos;
				if (store.find (rq.item_data.item, out pos)) {
					store.remove (pos);
				} else {
					requires_refresh = true;
				}
			} catch (Error e) {
				app.toast (_("Couldn't delete '%s': %s").printf (GLib.Markup.escape_text (rq.item_data.name), e.message));
				warning (@"Couldn't delete item '$(rq.item_data.name)': $(e.code) $(e.message)");
			}
		}

		if (requires_refresh) on_refresh ();
	}

	private void upload_pick () {
		var chooser = new Gtk.FileDialog () {
			title = _("Upload Files"),
			modal = true
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
				warning (@"Couldn't get the result of FileDialog for Drive: $(e.message)");
			}
		});
	}

	private async void upload_files (owned File[] files_to_upload) {
		if (files_to_upload.length == 0) return;
		if (this.current_folder.files == null) {
			this.current_folder.files = new Gee.ArrayList<API.Iceshrimp.File> ();
		}

		string[] reserved = {};
		foreach (var file in this.current_folder.files) {
			reserved += file.id;
		}

		int folders_start_pos = this.current_folder.folders == null ? 0 : this.current_folder.folders.size;
		string to_folder = this.current_folder.id;
		foreach (File file in files_to_upload) {
			try {
				API.Iceshrimp.File is_file = yield upload_file_real (to_folder, file);
				if (is_file.id in reserved) {
					// translators: toast popping up when a user uploads a file that already exists in drive
					//				The variable is a string filename.
					app.toast (_("'%s' already exists").printf (is_file.filename));
				} else {
					this.current_folder.files.insert (0, is_file);
					store.splice (folders_start_pos, 0, { new Item.from_file (is_file) });
					reserved += is_file.id;
				}
			} catch (Error e) {
				warning (@"$(e.message) $(e.code)");
			}
		}
	}

	private async API.Iceshrimp.File upload_file_real (string? to_folder, GLib.File file) throws Error {
		//  bytes_written = 0;
		//  total_bytes = 0;

		Bytes buffer;
		string mime;
		string uri = file.get_uri ();
		debug (@"Uploading new media: $(uri)…");

		{
			uint8[] contents;
			try {
				file.load_contents (null, out contents, null);
				GLib.FileInfo type = file.query_info (GLib.FileAttribute.STANDARD_CONTENT_TYPE, 0);
				mime = type.get_content_type ();
			} catch (Error e) {
				throw new Oopsie.INTERNAL ("Can't open file %s:\n%s".printf (uri, e.message));
			}
			buffer = new Bytes.take (contents);
			//  total_bytes = buffer.get_size ();
		}

		string? filename = file.get_basename ();
		if (filename == null) filename = mime.replace ("/", ".");

		var multipart = new Soup.Multipart (Soup.FORM_MIME_TYPE_MULTIPART);
		multipart.append_form_file ("file", filename, mime, buffer);

		string folder_id = to_folder == null ? "" : @"?folderId=$to_folder";
		var msg = new Soup.Message.from_multipart (@"$(accounts.active.instance)/api/iceshrimp/drive$folder_id", multipart);
		msg.request_headers.append ("Authorization", @"Bearer $(accounts.active.tuba_iceshrimp_api_key)");
		//  msg.wrote_body_data.connect (on_upload_bytes_written);

		string? error = null;
		InputStream? in_stream = null;
		network.queue (msg, null,
			(t_is) => {
				in_stream = t_is;
				upload_file_real.callback ();
			},
			(code, reason) => {
				error = reason;
				upload_file_real.callback ();
			}
		);
		yield;

		if (error != null || in_stream == null) {
			throw new Oopsie.INTERNAL (error);
		}

		//  this.progress = 1;
		var parser = Network.get_parser_from_inputstream (in_stream);
		var node = network.parse_node (parser);
		var entity = (API.Iceshrimp.File) Helper.Entity.from_json (node, typeof (API.Iceshrimp.File));

		//  this.media_id = entity.id;
		//  this.kind = MediaType.from_string (entity.kind);
		//  var working_loader = new AttachmentThumbnailer (uri, this.kind);
		//  working_loader.done.connect (on_done);
		//  #if GEXIV2
		//  	working_loader.extracted_alt.connect (on_extracted_alt_text);
		//  #endif

		//  debug (@"OK! ID $(entity.id)");

		// translators: screen reader announcement when the
		//				drive successfully uploads a file
		this.announce (_("Finished Uploading File"), LOW);

		return entity;
	}
}
