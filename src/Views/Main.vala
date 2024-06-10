public class Tuba.Views.Main : Views.TabbedBase {
	public class NotificationKind : Object {
		public string id { get; construct set; }
		public string title { get; construct set; }
		public string icon_name { get; construct set; }

		public NotificationKind (string? id, string? title, string? icon_name) {
			Object (id: id, title: title, icon_name: icon_name);
		}

		public static EqualFunc<string> compare = (a, b) => {
			return ((NotificationKind) a).id == ((NotificationKind) b).id;
		};
	}

	Views.Notifications notification_view;
	construct {
		is_main = true;

		add_tab (new Views.Home ());
		notification_view = new Views.Notifications ();
		add_tab (notification_view);
		add_tab (new Views.Conversations ());

		notification_kind_list.splice (0, 0, {
			new NotificationKind ("", _("All"), "tuba-funnel-symbolic"),
			new NotificationKind (InstanceAccount.KIND_MENTION, _("Mentions"), "tuba-chat-symbolic"),
			new NotificationKind (InstanceAccount.KIND_FAVOURITE, _("Favorites"), "starred-symbolic"),
			new NotificationKind (InstanceAccount.KIND_REBLOG, _("Boosts"), "tuba-media-playlist-repeat-symbolic"),
			new NotificationKind (InstanceAccount.KIND_POLL, _("Polls"), "tuba-check-round-outline-symbolic"),
			new NotificationKind (InstanceAccount.KIND_EDITED, _("Post Edits"), "document-edit-symbolic"),
			new NotificationKind (InstanceAccount.KIND_FOLLOW, _("Follows"), "contact-new-symbolic")
		});

		setup_notifications_filter_button ();
	}

	public string visible_child_name {
		get {
			return stack.visible_child_name;
		}
	}

	private Gtk.DropDown notifications_filter_button;
	private ListStore notification_kind_list = new ListStore (typeof (NotificationKind));

	private Gtk.Button search_button;
	protected override void on_view_switched () {
		base.on_view_switched ();

		bool is_notifications = (stack.visible_child as Views.Notifications) != null;
		notifications_filter_button.visible = is_notifications;
	}

	// Unused
	//  private void go_home () {
	//  	((Views.TabbedBase) app.main_window.main_page.child).change_page_to_named ("1");
	//  	app.main_window.update_selected_home_item ();
	//  }

	private Gtk.Stack title_wrapper_stack;
	public bool title_wrapper_stack_visible {
		get {
			return title_wrapper_stack.visible_child_name == "title";
		}
		set {
			title_wrapper_stack.visible_child_name = (value ? "stack" : "title");
		}
	}

	private void bind () {
		app.bind_property ("is-mobile", search_button, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.bind_property ("is-mobile", switcher_bar, "visible", GLib.BindingFlags.SYNC_CREATE);
		app.bind_property ("is-mobile", this, "title-wrapper-stack-visible", GLib.BindingFlags.SYNC_CREATE);
	}

	public override void build_header () {
		base.build_header ();
		header.title_widget = null;

		title_wrapper_stack = new Gtk.Stack ();
		title_wrapper_stack.add_named (title_stack, "stack");
		var title_header = new Adw.WindowTitle (label, "");
		bind_property ("label", title_header, "title", BindingFlags.SYNC_CREATE);
		title_wrapper_stack.add_named (title_header, "title");
		header.title_widget = title_wrapper_stack;

		search_button = new Gtk.Button () {
			icon_name = "tuba-loupe-large-symbolic",
			tooltip_text = _("Search")
		};
		search_button.clicked.connect (open_search);
		header.pack_end (search_button);

		notifications_filter_button = new Gtk.DropDown (notification_kind_list, null) {
			expression = new Gtk.PropertyExpression (typeof (NotificationKind), null, "title"),
			factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/notification_filter_title.ui"),
			list_factory = new Gtk.BuilderListItemFactory.from_resource (null, @"$(Build.RESOURCES)gtk/dropdown/notification_filter.ui"),
			tooltip_text = _("Filter"),
			show_arrow = false
		};
		header.pack_end (notifications_filter_button);

		var sidebar_button = new Gtk.ToggleButton ();
		header.pack_start (sidebar_button);
		sidebar_button.icon_name = "tuba-dock-left-symbolic";

		bind ();
		ulong main_window_notify = 0;
		main_window_notify = app.notify["main-window"].connect (() => {
			if (app.main_window == null) {
				sidebar_button.hide ();
				return;
			}

			app.main_window.split_view.bind_property (
				"collapsed",
				sidebar_button,
				"visible",
				BindingFlags.SYNC_CREATE
			);

			app.main_window.split_view.bind_property (
				"show-sidebar",
				sidebar_button,
				"active",
				BindingFlags.SYNC_CREATE | BindingFlags.BIDIRECTIONAL
			);

			app.disconnect (main_window_notify);
		});

	}

	void open_search () {
		app.main_window.open_view (new Views.Search ());
	}

	void setup_notifications_filter_button () {
		uint notification_filter_index;
		if (
			notification_kind_list.find_with_equal_func (
				new NotificationKind (settings.notifications_filter, null, null),
				NotificationKind.compare,
				out notification_filter_index
			)
		) {
			notifications_filter_button.selected = notification_filter_index;
		} else {
			settings.notifications_filter = "all";
		}

		notifications_filter_button.notify["selected"].connect (on_notification_filter_change);
	}

	void on_notification_filter_change () {
		NotificationKind kind = (NotificationKind) notifications_filter_button.selected_item;
		settings.notifications_filter = kind.id == "" ? "all" : kind.id;
		notification_view.change_filter (kind.id);
	}
}
