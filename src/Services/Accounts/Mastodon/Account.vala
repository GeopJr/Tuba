public class Tooth.Mastodon.Account : InstanceAccount {

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

	public static Place PLACE_HOME = new Place() {
		title = _("Home"), 
		icon = "tooth-home-symbolic",
		open_func = win => {
			//  win.open_view (new Views.Main ());
			//  win.back();
			win.go_back_to_start();
		}
	};

	//  public static Place PLACE_NOTIFICATIONS = new Place () {
	//  	title = _("Notifications"),
	//  	icon = "tooth-bell-symbolic",
	//  	open_func = win => {
	//  		win.open_view (new Views.Notifications ());
	//  	}
	//  };

	public static Place PLACE_MESSAGES = new Place () {
		title = _("Direct Messages"),
		icon = "tooth-mail-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.Conversations ()));
		}
	};

	public static Place PLACE_BOOKMARKS = new Place () {
		title = _("Bookmarks"),
		icon = "tooth-bookmarks-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.Bookmarks ()));
		}
	};

	public static Place PLACE_FAVORITES = new Place () {
		title = _("Favorites"),
		icon = "tooth-unstarred-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.Favorites ()));
		}
	};

	public static Place PLACE_LISTS = new Place () {
		title = _("Lists"),
		icon = "tooth-list-compact-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.Lists ()));
		}
	};

	//  public static Place PLACE_SEARCH = new Place () {
	//  	title = _("Search"),
	//  	icon = "system-search-symbolic",
	//  	open_func = (win) => {
	//  		win.open_view (new Views.Search ());
	//  	}
	//  };

	public static Place PLACE_LOCAL = new Place () {
		title = _("Local"),
		icon = "tooth-network-server-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.Local ()));
		}
	};

	public static Place PLACE_FEDERATED = new Place () {
		title = _("Federated"),
		icon = "tooth-globe-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.Federated ()));
		}
	};

	public static Place PLACE_FOLLOW_REQUESTS = new Place () {
		title = _("Follow Requests"),
		icon = "tooth-address-book-new-symbolic",
		open_func = (win) => {
			win.open_view (set_as_sidebar_item(new Views.FollowRequests ()));
		}
	};

	public override void register_known_places (GLib.ListStore places) {
		places.append (PLACE_HOME);
		//  places.append (PLACE_SEARCH);

		places.append (PLACE_LOCAL);
		places.append (PLACE_FEDERATED);

		places.append (PLACE_FAVORITES);
		places.append (PLACE_BOOKMARKS);
		places.append (PLACE_LISTS);

		places.append (PLACE_FOLLOW_REQUESTS);
	}

	construct {
		// bind_property ("unread_count", notifications_item, "badge", BindingFlags.SYNC_CREATE);

		// Populate possible visibility variants
		set_visibility (new Visibility () {
			id = "public",
			name = _("Public"),
			icon_name = "tooth-globe-symbolic",
			description = _("Post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "unlisted",
			// translators: Probably follow Mastodon's translation
			name = _("Unlisted"),
			icon_name = "tooth-padlock2-open-symbolic",
			description = _("Don\'t post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "private",
			name = _("Followers Only"),
			icon_name = "tooth-padlock2-symbolic",
			description = _("Post to followers only")
		});
		set_visibility (new Visibility () {
			id = "direct",
			name = _("Direct"),
			icon_name = "tooth-mail-symbolic",
			description = _("Post to mentioned users only")
		});
	}

	private static Views.Base set_as_sidebar_item (Views.Base view) {
		view.is_sidebar_item = true;
		return view;
	}
}
