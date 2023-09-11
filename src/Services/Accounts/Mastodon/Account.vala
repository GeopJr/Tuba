public class Tuba.Mastodon.Account : InstanceAccount {

	public const string BACKEND = "Mastodon";

	class Test : AccountStore.BackendTest {
		public override string? get_backend (Json.Object obj) {
			return BACKEND; // Always treat instances as compatible with Mastodon
		}
	}

	public static void register (AccountStore store) {
		store.backend_tests.add (new Test ());
		store.create_for_backend[BACKEND].connect ((node) => {
			try {
				var account = Entity.from_json (typeof (Account), node) as Account;
				account.backend = BACKEND;
				return account;
			} catch (Error e) {
				warning (@"Error creating backend: $(e.message)");
			}
			return null;
		});
	}

	public static Place PLACE_HOME = new Place () { // vala-lint=naming-convention

		icon = "tuba-home-symbolic",
		title = _("Home"),
		open_func = win => {
			//  win.open_view (new Views.Main ());
			//  win.back();
			win.go_back_to_start ();
			((Views.TabbedBase) win.main_page.child).change_page_to_named ("1");
		}
	};

	public static Place PLACE_NOTIFICATIONS = new Place () { // vala-lint=naming-convention

		title = _("Notifications"),
		icon = "tuba-bell-outline-symbolic",
		open_func = win => {
			win.go_back_to_start ();
			((Views.TabbedBase) win.main_page.child).change_page_to_named ("2");
		}
	};

	public static Place PLACE_CONVERSATIONS = new Place () { // vala-lint=naming-convention

		title = _("Conversations"),
		icon = "mail-unread-symbolic",
		open_func = win => {
			win.go_back_to_start ();
			((Views.TabbedBase) win.main_page.child).change_page_to_named ("3");
		}
	};

	//  public static Place PLACE_MESSAGES = new Place () { // vala-lint=naming-convention

	//  	icon = "tuba-mail-symbolic",
	//  	title = _("Direct Messages"),
	//  	open_func = (win) => {
	//  		win.open_view (set_as_sidebar_item (new Views.Conversations ()));
	//  	}
	//  };

	public static Place PLACE_BOOKMARKS = new Place () { // vala-lint=naming-convention

		icon = "tuba-bookmarks-symbolic",
		title = _("Bookmarks"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Bookmarks ()));
		}
	};

	public static Place PLACE_FAVORITES = new Place () { // vala-lint=naming-convention

		icon = "tuba-unstarred-symbolic",
		title = _("Favorites"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Favorites ()));
		}
	};

	public static Place PLACE_LISTS = new Place () { // vala-lint=naming-convention

		icon = "tuba-list-compact-symbolic",
		title = _("Lists"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Lists ()));
		}
	};

	public static Place PLACE_SEARCH = new Place () { // vala-lint=naming-convention

		title = _("Search"),
		icon = "system-search-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Search ());
		}
	};

	public static Place PLACE_EXPLORE = new Place () { // vala-lint=naming-convention

		icon = "tuba-explore2-large-symbolic",
		title = _("Explore"),
		separated = true,
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Explore ()));
		}
	};

	public static Place PLACE_LOCAL = new Place () { // vala-lint=naming-convention

		icon = "tuba-network-server-symbolic",
		title = _("Local"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Local ()));
		}
	};

	public static Place PLACE_FEDERATED = new Place () { // vala-lint=naming-convention

		icon = "tuba-globe-symbolic",
		title = _("Federated"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Federated ()));
		}
	};

	public static Place PLACE_FOLLOW_REQUESTS = new Place () { // vala-lint=naming-convention

		icon = "tuba-address-book-new-symbolic",
		title = _("Follow Requests"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.FollowRequests ()));
		}
	};

	public static Place PLACE_HASHTAGS = new Place () { // vala-lint=naming-convention

		icon = "tuba-hashtag-symbolic",
		title = _("Hashtags"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Hashtags ()));
		}
	};

	public static Place PLACE_ANNOUNCEMENTS = new Place () { // vala-lint=naming-convention

		icon = "tuba-lightbulb-symbolic",
		title = _("Announcements"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Announcements ()));
		}
	};

	public override void register_known_places (GLib.ListStore places) {
		ulong main_window_notify = 0;
		main_window_notify = app.notify["main-window"].connect (() => {
			app.main_window.bind_property ("is-mobile", PLACE_NOTIFICATIONS, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
			app.main_window.bind_property ("is-mobile", PLACE_CONVERSATIONS, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
			app.main_window.bind_property ("is-mobile", PLACE_SEARCH, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
			app.disconnect (main_window_notify);
		});

		places.append (PLACE_HOME);
		places.append (PLACE_NOTIFICATIONS);
		places.append (PLACE_CONVERSATIONS);
		places.append (PLACE_SEARCH);
		places.append (PLACE_FAVORITES);
		places.append (PLACE_BOOKMARKS);
		places.append (PLACE_HASHTAGS);

		places.append (PLACE_EXPLORE);
		places.append (PLACE_LOCAL);
		places.append (PLACE_FEDERATED);
		places.append (PLACE_LISTS);

		// TODO: Move to menu button?
		places.append (PLACE_ANNOUNCEMENTS);
		places.append (PLACE_FOLLOW_REQUESTS);
	}

	construct {
		// bind_property ("unread_count", notifications_item, "badge", BindingFlags.SYNC_CREATE);

		// Populate possible visibility variants
		set_visibility (new Visibility () {
			id = "public",
			name = _("Public"),
			icon_name = "tuba-globe-symbolic",
			small_icon_name = "tuba-globe-small-symbolic",
			description = _("Post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "unlisted",
			// translators: Probably follow Mastodon's translation
			name = _("Unlisted"),
			icon_name = "tuba-padlock2-open-symbolic",
			small_icon_name = "tuba-padlock2-open-small-symbolic",
			description = _("Don\'t post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "private",
			name = _("Followers Only"),
			icon_name = "tuba-padlock2-symbolic",
			small_icon_name = "tuba-padlock2-small-symbolic",
			description = _("Post to followers only")
		});
		set_visibility (new Visibility () {
			id = "direct",
			name = _("Direct"),
			icon_name = "mail-unread-symbolic",
			small_icon_name = "tuba-mail-small-symbolic",
			description = _("Post to mentioned users only")
		});
	}

	private static Views.Base set_as_sidebar_item (Views.Base view) {
		view.is_sidebar_item = true;
		return view;
	}
}
