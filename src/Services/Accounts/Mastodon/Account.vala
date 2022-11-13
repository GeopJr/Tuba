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

	public static Place PLACE_NOTIFICATIONS = new Place () {
		title = _("Notifications"),
		icon = "bell-symbolic",
		open_func = win => {
			win.open_view (new Views.Notifications ());
		}
	};

	public static Place PLACE_MESSAGES = new Place () {
		title = _("Direct Messages"),
		icon = "mail-unread-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Conversations ());
		}
	};

	public static Place PLACE_BOOKMARKS = new Place () {
		title = _("Bookmarks"),
		icon = "user-bookmarks-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Bookmarks ());
		}
	};

	public static Place PLACE_FAVORITES = new Place () {
		title = _("Favorites"),
		icon = "starred-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Favorites ());
		}
	};

	public static Place PLACE_LISTS = new Place () {
		title = _("Lists"),
		icon = "view-list-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Lists ());
		}
	};

	public static Place PLACE_SEARCH = new Place () {
		title = _("Search"),
		icon = "system-search-symbolic",
		open_func = (win) => {
			win.open_view (new Views.Search ());
		}
	};

	public override void register_known_places (GLib.ListStore places) {
		places.append (PLACE_NOTIFICATIONS);
		places.append (PLACE_MESSAGES);
		places.append (PLACE_BOOKMARKS);
		places.append (PLACE_FAVORITES);
		places.append (PLACE_LISTS);
		places.append (PLACE_SEARCH);
	}

	construct {
		// bind_property ("unread_count", notifications_item, "badge", BindingFlags.SYNC_CREATE);

		// Populate possible visibility variants
		set_visibility (new Visibility () {
			id = "public",
			name = _("Public"),
			icon_name = "globe-symbolic",
			description = _("Post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "unlisted",
			name = _("Unlisted"),
			icon_name = "changes-allow-symbolic",
			description = _("Don\'t post to public timelines")
		});
		set_visibility (new Visibility () {
			id = "private",
			name = _("Followers-only"),
			icon_name = "changes-prevent-symbolic",
			description = _("Post to followers only")
		});
		set_visibility (new Visibility () {
			id = "direct",
			name = _("Direct"),
			icon_name = "mail-unread-symbolic",
			description = _("Post to mentioned users only")
		});
	}

	public override void describe_kind (string kind, out string? icon, out string? descr, API.Account account) {
		switch (kind) {
			case KIND_MENTION:
				icon = "user-available-symbolic";
				descr = _("<span underline=\"none\"><a href=\"%s\">%s</a> mentioned you</span>").printf (account.url, account.display_name);
				break;
			case KIND_REBLOG:
				icon = "media-playlist-repeat-symbolic";
				descr = _("<span underline=\"none\"><a href=\"%s\">%s</a> boosted your status</span>").printf (account.url, account.display_name);
				break;
			case KIND_REMOTE_REBLOG:
				icon = "media-playlist-repeat-symbolic";
				descr = _("<span underline=\"none\"><a href=\"%s\">%s</a> boosted</span>").printf (account.url, account.display_name);
				break;
			case KIND_FAVOURITE:
				icon = "starred-symbolic";
				descr = _("<span underline=\"none\"><a href=\"%s\">%s</a> favorited your status</span>").printf (account.url, account.display_name);
				break;
			case KIND_FOLLOW:
				icon = "contact-new-symbolic";
				descr = _("<span underline=\"none\"><a href=\"%s\">%s</a> now follows you</span>").printf (account.url, account.display_name);
				break;
			case KIND_FOLLOW_REQUEST:
				icon = "contact-new-symbolic";
				descr = _("<span underline=\"none\"><a href=\"%s\">%s</a> wants to follow you</span>").printf (account.url, account.display_name);
				break;
			case KIND_POLL:
				icon = "emblem-default-symbolic";
				descr = _("Poll results");
				break;
			default:
				icon = null;
				descr = null;
				break;
		}
	}

}
