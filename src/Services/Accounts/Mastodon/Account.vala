public class Tuba.Mastodon.Account : InstanceAccount {
	public static Place PLACE_HOME = new Place () { // vala-lint=naming-convention

		icon = "tuba-user-home-symbolic",
		title = _("Home"),
		needs_attention = false,
		open_func = win => {
			//  win.open_view (new Views.Main ());
			//  win.back();
			win.go_back_to_start ();
			((Views.TabbedBase) win.main_page.child).change_page_to_named ("1");
			win.set_sidebar_selected_item (0);
		}
	};

	public static Place PLACE_NOTIFICATIONS = new Place () { // vala-lint=naming-convention

		icon = "tuba-bell-outline-symbolic",
		title = _("Notifications"),
		open_func = win => {
			win.go_back_to_start ();
			((Views.TabbedBase) win.main_page.child).change_page_to_named ("2");
			win.set_sidebar_selected_item (1);
		}
	};

	public static Place PLACE_CONVERSATIONS = new Place () { // vala-lint=naming-convention

		icon = "tuba-mail-unread-symbolic",
		title = _("Conversations"),
		open_func = win => {
			win.go_back_to_start ();
			((Views.TabbedBase) win.main_page.child).change_page_to_named ("3");
			win.set_sidebar_selected_item (2);
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

		icon = "tuba-loupe-large-symbolic",
		title = _("Search"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Search ()));
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

	public static Place PLACE_BUBBLE = new Place () { // vala-lint=naming-convention

		icon = "tuba-fish-symbolic",
		title = "Bubble", // NOTE: Leave untranslated for now
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Bubble ()));
		},
		visible = false
	};

	public static Place PLACE_FEDERATED = new Place () { // vala-lint=naming-convention

		icon = "tuba-globe-symbolic",
		title = _("Federated"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Federated ()));
		}
	};

	public static Place PLACE_HASHTAGS = new Place () { // vala-lint=naming-convention

		icon = "tuba-hashtag-symbolic",
		title = _("Hashtags"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Hashtags ()));
		}
	};

	public static Place PLACE_DRIVE = new Place () { // vala-lint=naming-convention

		icon = "tuba-folder-visiting-symbolic",
		title = _("Drive"),
		open_func = (win) => {
			win.open_view (set_as_sidebar_item (new Views.Drive ()));
		}
	};

	private static Place[] SIDEBAR_PLACES = { // vala-lint=naming-convention
		PLACE_HOME,
		PLACE_NOTIFICATIONS,
		PLACE_CONVERSATIONS,
		PLACE_SEARCH,
		PLACE_FAVORITES,
		PLACE_BOOKMARKS,
		PLACE_HASHTAGS,

		PLACE_EXPLORE,
		PLACE_LOCAL,
		PLACE_BUBBLE,
		PLACE_FEDERATED,
		PLACE_LISTS,
		PLACE_DRIVE
	};

	protected override void bump_sidebar_items () {
		PLACE_BUBBLE.visible = (this.instance_info != null && this.instance_info.supports_bubble) || BUBBLE in this.tuba_instance_features;
		PLACE_DRIVE.visible = ICESHRIMP in this.tuba_instance_features;
	}

	public override void register_known_places (GLib.ListStore places) {
		app.bind_property ("is-mobile", PLACE_NOTIFICATIONS, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		app.bind_property ("is-mobile", PLACE_CONVERSATIONS, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);
		app.bind_property ("is-mobile", PLACE_SEARCH, "visible", GLib.BindingFlags.SYNC_CREATE | GLib.BindingFlags.INVERT_BOOLEAN);

		places.splice (
			0,
			0,
			SIDEBAR_PLACES
		);
	}

	public override void register_extra (GLib.ListStore places, Place[]? extra = null) {
		places.splice (
			0,
			places.n_items,
			{}
		);

		if (extra != null && extra.length > 0) {
			extra[0].separated = true;

			places.splice (
				places.n_items,
				0,
				extra
			);
		}
	}

	construct {
		// bind_property ("unread_count", notifications_item, "badge", BindingFlags.SYNC_CREATE);

		// Populate possible visibility variants
		set_visibility (new Visibility () {
			id = API.Status.Visibility.PUBLIC.to_string (),
			name = API.Status.Visibility.PUBLIC.to_title (),
			icon_name = "tuba-globe-symbolic",
			small_icon_name = "tuba-globe-small-symbolic",
			description = _("Post to public timelines")
		});
		set_visibility (new Visibility () {
			id = API.Status.Visibility.UNLISTED.to_string (),
			name = API.Status.Visibility.UNLISTED.to_title (),
			icon_name = "tuba-padlock2-open-symbolic",
			small_icon_name = "tuba-padlock2-open-small-symbolic",
			description = _("Don\'t post to public timelines")
		});
		set_visibility (new Visibility () {
			id = API.Status.Visibility.PRIVATE.to_string (),
			name = API.Status.Visibility.PRIVATE.to_title (),
			icon_name = "tuba-padlock2-symbolic",
			small_icon_name = "tuba-padlock2-small-symbolic",
			description = _("Post to followers only")
		});
		set_visibility (new Visibility () {
			id = API.Status.Visibility.DIRECT.to_string (),
			name = API.Status.Visibility.DIRECT.to_title (),
			icon_name = "tuba-mail-unread-symbolic",
			small_icon_name = "tuba-mail-small-symbolic",
			description = _("Post to mentioned users only")
		});
	}

	// Notification actions
	public override void open_status_url (string url) {
		if (!Widgets.RichLabel.should_resolve_url (url)) return;

		resolve.begin (url, (obj, res) => {
			try {
				resolve.end (res).open ();
				app.main_window.present ();
			} catch (Error e) {
				warning (@"Failed to resolve URL \"$url\":");
				warning (e.message);
				Utils.Host.open_url.begin (url);
			}
		});
	}

	private bool check_issuer (string issuer_id) {
		if (issuer_id == this.id) return true;

		var dlg = app.inform (
			_("Error"),
			//  translators: this error shows up when the user clicks a button
			//				 in a desktop notification that was pushed for a
			//				 different account
			_("Notification was pushed for a different account")
		);
		dlg.present (app.main_window);

		return false;
	}

	public override void answer_follow_request (string issuer_id, string fr_id, bool accept) {
		if (!check_issuer (issuer_id)) return;

		new Request.POST (@"/api/v1/follow_requests/$fr_id/$(accept ? "authorize" : "reject")")
			.with_account (this)
			.exec ();
	}

	public override void follow_back (string issuer_id, string acc_id) {
		if (!check_issuer (issuer_id)) return;

		API.Relationship relationship = new API.Relationship.for_account_id (acc_id);

		ulong invalidate_signal_id = 0;
		invalidate_signal_id = relationship.invalidated.connect (() => {
			if (!relationship.following) {
				new Request.POST (@"/api/v1/accounts/$acc_id/follow")
					.with_account (this)
					.exec ();
			}

			relationship.disconnect (invalidate_signal_id);
		});
	}

	public override void remove_from_followers (string issuer_id, string acc_id) {
		if (!check_issuer (issuer_id)) return;

		new Request.POST (@"/api/v1/accounts/$acc_id/remove_from_followers")
			.with_account (this)
			.exec ();
	}

	public override void reply_to_status_uri (string issuer_id, string uri) {
		if (!check_issuer (issuer_id)) return;

		//  if (Tuba.EntityCache.contains (uri)) {
		//  	var status = Tuba.EntityCache.lookup (uri) as API.Status;
		//  	new Dialogs.Compose.reply (status.formal);
		//  } else {
			resolve.begin (uri, (obj, res) => {
				try {
					var status = resolve.end (res) as API.Status;
					if (status != null) {
						new Dialogs.Composer.Dialog.reply (status.formal);
						app.main_window.present ();
					}
				} catch (Error e) {
					warning (@"Failed to resolve URL \"$url\":");
					warning (e.message);
				}
			});
		//  }
	}
}
