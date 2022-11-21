public class Tooth.Mastodon.Account : InstanceAccount {

	public const string BACKEND = "Mastodon";

	public const string KIND_MENTION = "mention";
	public const string KIND_REBLOG = "reblog";
	public const string KIND_FAVOURITE = "favourite";
	public const string KIND_FOLLOW = "follow";
	public const string KIND_POLL = "poll";
	public const string KIND_FOLLOW_REQUEST = "__follow-request";
	public const string KIND_REMOTE_REBLOG = "__remote-reblog";

	class Test : AccountStore.BackendTest {
		public override string? get_backend (Json.Object obj) {
			return BACKEND; // Always treat instances as compatible with Mastodon
		}
	}

	public static void register (AccountStore store) {
		store.backend_tests.add (new Test ());
		store.create_for_backend[BACKEND].connect ((node) => {
			var account = Entity.from_json (typeof (Account), node) as Account;
			account.backend = BACKEND;
			return account;
		});
	}

	public static Place PLACE_HOME = new Place() {
		title = _("Home"), 
		icon = "tooth-home-symbolic",
		open_func = win => {
			//  win.open_view (new Views.Main ());
			win.back();
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
			win.open_view (new Views.Conversations ());
		}
	};

	public static Place PLACE_BOOKMARKS = new Place () {
		title = _("Bookmarks"),
		icon = "tooth-bookmarks-filled-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Bookmarks ());
		}
	};

	public static Place PLACE_FAVORITES = new Place () {
		title = _("Favorites"),
		icon = "tooth-starred-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Favorites ());
		}
	};

	public static Place PLACE_LISTS = new Place () {
		title = _("Lists"),
		icon = "tooth-list-compact-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Lists ());
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
			win.open_view (new Views.Local ());
		}
	};

	public static Place PLACE_FEDERATED = new Place () {
		title = _("Federated"),
		icon = "tooth-globe-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Federated ());
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
			name = _("Unlisted"),
			icon_name = "tooth-padlock2-open-symbolic",
			description = _("Don\'t post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "private",
			name = _("Followers-only"),
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

	public override void describe_kind (string kind, out string? icon, out string? descr, API.Account account, out string? descr_url) {
		switch (kind) {
			case KIND_MENTION:
				icon = "tooth-chat-symbolic";
				descr = _("%s mentioned you").printf (account.display_name);
				descr_url = account.url;
				break;
			case KIND_REBLOG:
				icon = "tooth-media-playlist-repeat-symbolic";
				descr = _("%s boosted your status").printf (account.display_name);
				descr_url = account.url;
				break;
			case KIND_REMOTE_REBLOG:
				icon = "tooth-media-playlist-repeat-symbolic";
				descr = _("%s boosted").printf (account.display_name);
				descr_url = account.url;
				break;
			case KIND_FAVOURITE:
				icon = "tooth-starred-symbolic";
				descr = _("%s favorited your status").printf (account.display_name);
				descr_url = account.url;
				break;
			case KIND_FOLLOW:
				icon = "tooth-contact-new-symbolic";
				descr = _("%s now follows you").printf (account.display_name);
				descr_url = account.url;
				break;
			case KIND_FOLLOW_REQUEST:
				icon = "tooth-contact-new-symbolic";
				descr = _("%s wants to follow you").printf (account.display_name);
				descr_url = account.url;
				break;
			case KIND_POLL:
				icon = "tooth-check-round-outline-symbolic";
				descr = _("Poll results");
				descr_url = null;
				break;
			default:
				icon = null;
				descr = null;
				descr_url = null;
				break;
		}
	}

}
