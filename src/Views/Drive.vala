public class Tuba.Views.Drive : Views.Base {
	public class Item : GLib.Object {
		public API.Iceshrimp.Folder? folder { get; set; default=null; }
		public API.Iceshrimp.File? file { get; set; default=null; }

		public Item.from_folder (API.Iceshrimp.Folder folder) {
			this.folder = folder;
		}

		public Item.from_file (API.Iceshrimp.File file) {
			this.file = file;
		}
	}

	public class ItemWidget : Gtk.Box {
		Gtk.Image image;
		Gtk.Label label;
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

			this.append (image);
			this.append (label);
		}

		public void populate (Item item) {
			if (item.folder != null) {
				(Adw.StyleManager.get_default ()).notify["accent-color-rgba"].connect (update_folder_color);
				update_folder_color ();
				label.label = item.folder.name;
			} else {
				if (item.file.contentType.has_prefix ("image/") || item.file.contentType.has_prefix ("audio/")) Helper.Image.request_paintable (item.file.thumbnailUrl.replace ("https://shrimp.example.org", accounts.active.instance), null, false, on_thumbnail_loaded);
				label.label = item.file.filename;
			}
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

	private Gtk.Button go_back_btn;
	private Gtk.Button create_folder_btn;
	private Gtk.Button upload_file_btn;
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

		create_folder_btn = new Gtk.Button () {
			icon_name = "tuba-folder-new-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("Create Folder")
		};
		//  create_folder_btn.clicked.connect (on_create_folder);

		upload_file_btn = new Gtk.Button () {
			icon_name = "tuba-plus-large-symbolic",
			css_classes = { "flat" },
			tooltip_text = _("Upload File")
		};
		//  upload_file_btn.clicked.connect (on_upload_file);

		header.pack_end (upload_file_btn);
		header.pack_end (create_folder_btn);
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
		selection = new Gtk.MultiSelection (store);
		grid = new Gtk.GridView (selection, signallistitemfactory) {
			enable_rubberband = true,
			single_click_activate = false
		};
		grid.activate.connect (on_item_activated);
		grid.remove_css_class ("view");
		content_box.child = grid;

		load_folder ();
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
			})
			.on_error (on_error)
			.exec ();
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
		list_item.set_child (item_widget);
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
		var item = (Item) store.get_item (pos);
		if (item.folder != null) {
			load_folder (item.folder.id);
		} else if (item.file.contentType.has_prefix ("image/")) {
			app.main_window.show_media_viewer (item.file.url.replace ("https://shrimp.example.org", accounts.active.instance), Attachment.MediaType.IMAGE, null);
		} else if (item.file.contentType.has_prefix ("audio/")) {
			app.main_window.show_media_viewer (item.file.url.replace ("https://shrimp.example.org", accounts.active.instance), Attachment.MediaType.AUDIO, null);
		} else {
			Utils.Host.open_url.begin (item.file.url);
		}
	}
}
