public class Tootle.Mastodon.Account : InstanceAccount {

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



    public Views.Sidebar.Item notifications_item;

    construct {
        notifications_item = new Views.Sidebar.Item () {
			label = "Notifications",
			icon = "bell-symbolic",
			on_activated = () => {
			    app.main_window.open_view (new Views.Notifications ());
			}
		};
		bind_property ("unread_count", notifications_item, "badge", BindingFlags.SYNC_CREATE);

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

	public override void populate_user_menu (GLib.ListStore model) {
		// model.append (new Views.Sidebar.Item () {
		// 	label = "Timelines",
		// 	icon = "user-home-symbolic"
		// });
		model.append (notifications_item);
		model.append (new Views.Sidebar.Item () {
			label = "Direct Messages",
			icon = "mail-unread-symbolic",
			on_activated = () => {
			    app.main_window.open_view (new Views.Conversations ());
			}
		});
		model.append (new Views.Sidebar.Item () {
			label = "Bookmarks",
			icon = "user-bookmarks-symbolic",
			on_activated = () => {
			    app.main_window.open_view (new Views.Bookmarks ());
			}
		});
		model.append (new Views.Sidebar.Item () {
			label = "Favorites",
			icon = "non-starred-symbolic",
			on_activated = () => {
			    app.main_window.open_view (new Views.Favorites ());
			}
		});
		model.append (new Views.Sidebar.Item () {
			label = "Lists",
			icon = "view-list-symbolic",
			on_activated = () => {
			    app.main_window.open_view (new Views.Lists ());
			}
		});
		model.append (new Views.Sidebar.Item () {
			label = "Search",
			icon = "system-search-symbolic",
			on_activated = () => {
			    app.main_window.open_view (new Views.Search ());
			}
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
