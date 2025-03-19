[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/view.ui")]
public class Tuba.Views.Sidebar : Gtk.Widget, AccountHolder {
	public const int MAX_SIDEBAR_LISTS = 25;

	[GtkChild] unowned Gtk.ListBox items;
	[GtkChild] unowned Gtk.ListBox saved_accounts;
	[GtkChild] unowned Widgets.Avatar accounts_button_avi;
	[GtkChild] unowned Gtk.MenuButton menu_btn;
	[GtkChild] unowned Gtk.Popover account_switcher_popover_menu;
	[GtkChild] unowned Adw.Banner announcements_banner;
	[GtkChild] unowned Adw.Banner fr_banner;
	[GtkChild] unowned Adw.Banner network_banner;

	protected InstanceAccount? account { get; set; default = null; }

	protected Gtk.SliceListModel app_items;
	protected Gtk.SliceListModel account_items;
	protected Gtk.FlattenListModel item_model;
	protected GLib.ListStore accounts_model;

	public int unread_announcements {
		set {
			if (value > 0) {
				announcements_banner.revealed = true;
				// tanslators: used in a banner, the variable is the number of unread announcements
				announcements_banner.title = GLib.ngettext ("%d Announcement", "%d Announcements", (ulong) value).printf (value);
			} else {
				announcements_banner.revealed = false;
			}
		}
	}

	public int unreviewed_follow_requests {
		set {
			if (value > 0) {
				fr_banner.revealed = true;
				// tanslators: used in a banner, the variable is the number of unreviewed follow requests
				fr_banner.title = GLib.ngettext ("%d Follow Request", "%d Follow Requests", (ulong) value).printf (value);
			} else {
				fr_banner.revealed = false;
			}
		}
	}

	public int tuba_wrapped {
		set {
			var wrapped_action = app.lookup_action ("open-last-fediwrapped") as SimpleAction;
			if (wrapped_action != null) {
				wrapped_action.set_enabled (value > 2000);
			}
		}
	}

	static construct {
		typeof (Widgets.Avatar).ensure ();
		typeof (Widgets.EmojiLabel).ensure ();
		set_layout_manager_type (typeof (Gtk.BinLayout));
	}

	construct {
		var menu_model = new GLib.Menu ();

		accounts_model = new GLib.ListStore (typeof (Object));
		saved_accounts.bind_model (accounts_model, on_accounts_row_create);

		var account_submenu_model = new GLib.Menu ();
		account_submenu_model.append (_("New Post"), "app.compose");
		account_submenu_model.append (_("Open Profile"), "app.open-current-account-profile");
		account_submenu_model.append (_("Refresh"), "app.refresh");
		menu_model.append_section (null, account_submenu_model);

		var misc_submenu_model = new GLib.Menu ();
		misc_submenu_model.append (_("Announcements"), "app.open-announcements");
		misc_submenu_model.append (_("Follow Requests"), "app.open-follow-requests");
		misc_submenu_model.append (_("Mutes & Blocks"), "app.open-mutes-blocks");
		misc_submenu_model.append (_("Draft Posts"), "app.open-draft-posts");
		misc_submenu_model.append (_("Scheduled Posts"), "app.open-scheduled-posts");

		// translators: main menu entry, please don't translate it unless you have to.
		//				Refer to other #FediWrapped strings for more info
		var wrapped_menu_item = new MenuItem (_("#FediWrapped"), "app.open-last-fediwrapped");
		wrapped_menu_item.set_attribute_value ("hidden-when", "action-disabled");
		misc_submenu_model.append_item (wrapped_menu_item);

		var admin_dahsboard_menu_item = new MenuItem (_("Admin Dashboard"), "app.open-admin-dashboard");
		admin_dahsboard_menu_item.set_attribute_value ("hidden-when", "action-disabled");
		misc_submenu_model.append_item (admin_dahsboard_menu_item);

		menu_model.append_section (null, misc_submenu_model);

		misc_submenu_model = new GLib.Menu ();
		misc_submenu_model.append (_("Preferences"), "app.open-preferences");
		misc_submenu_model.append (_("Keyboard Shortcuts"), "win.show-help-overlay");
		misc_submenu_model.append (_("About %s").printf (Build.NAME), "app.about");
		misc_submenu_model.append (_("Quit"), "app.quit");
		menu_model.append_section (null, misc_submenu_model);

		menu_btn.menu_model = menu_model;

		app_items = new Gtk.SliceListModel (null, 0, MAX_SIDEBAR_LISTS);
		account_items = new Gtk.SliceListModel (null, 0, 15);

		var models = new GLib.ListStore (typeof (Object));
		models.append (account_items);
		models.append (app_items);
		item_model = new Gtk.FlattenListModel (models);

		items.bind_model (item_model, on_item_create);
		items.set_header_func (on_item_header_update);
		saved_accounts.set_header_func (on_account_header_update);

		construct_account_holder ();
		announcements_banner.button_clicked.connect (view_announcements_cb);
		fr_banner.button_clicked.connect (view_fr_cb);

		app.notify["is-online"].connect (on_network_change);
		on_network_change ();
	}

	void on_network_change () {
		network_banner.revealed = !app.is_online;
	}

	public virtual Gtk.Widget on_accounts_row_create (Object obj) {
		var row = new AccountRow (obj as InstanceAccount);
		row.popdown_signal.connect (popdown);

		return row;
	}

	protected virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
		accounts_model.remove_all ();

		Object[] accounts_to_add = {};
		accounts.foreach (acc => {
			accounts_to_add += acc;

			return true;
		});
		accounts_to_add += new Object ();

		accounts_model.splice (0, 0, accounts_to_add);
		update_selected_account ();
	}

	private void update_selected_account () {
		uint index;
		if (accounts_model.find (account, out index))
			saved_accounts.select_row (saved_accounts.get_row_at_index ((int) index));
	}

	public void set_sidebar_selected_item (int index) {
		if (items != null) {
			items.select_row (items.get_row_at_index (index));
		}
	}

	private Binding sidebar_avatar_btn;
	private Binding announcements_banner_binding;
	private Binding fr_banner_binding;
	private Binding wrapped_binding;
	protected virtual void on_account_changed (InstanceAccount? account) {
		if (this.account != null) {
			sidebar_avatar_btn.unbind ();
			announcements_banner_binding.unbind ();
			fr_banner_binding.unbind ();
			wrapped_binding.unbind ();
		}
		this.tuba_wrapped = 0;
		unread_announcements = 0;

		if (app != null && app.main_window != null)
			app.main_window.go_back_to_start ();

		this.account = account;

		if (account != null) {
			announcements_banner_binding = this.account.bind_property ("unread-announcements", this, "unread-announcements", BindingFlags.SYNC_CREATE);
			fr_banner_binding = this.account.bind_property ("unreviewed-follow-requests", this, "unreviewed-follow-requests", BindingFlags.SYNC_CREATE);
			sidebar_avatar_btn = this.account.bind_property ("avatar", accounts_button_avi, "avatar-url", BindingFlags.SYNC_CREATE);
			wrapped_binding = this.account.bind_property ("tuba-last-fediwrapped-year", this, "tuba-wrapped", BindingFlags.SYNC_CREATE);
			account_items.model = account.known_places;
			app_items.model = account.list_places;
			update_selected_account ();

			var dashboard_action = app.lookup_action ("open-admin-dashboard") as SimpleAction;
			if (dashboard_action != null) {
				dashboard_action.set_enabled (this.account.admin_mode);
			}
		} else {
			saved_accounts.unselect_all ();

			account_items.model = null;
			app_items.model = null;
			accounts_button_avi.account = null;
		}
	}

	// Item
	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/item.ui")]
	protected class ItemRow : Gtk.ListBoxRow {
		public Place place {get; set;}

		[GtkChild] unowned Gtk.Image icon;
		[GtkChild] unowned Gtk.Label label;
		[GtkChild] unowned Gtk.Label badge;

		public ItemRow (Place place) {
			this.notify["visible"].connect (on_visibility_changed);
			this.place = place;
			place.bind_property ("title", label, "label", BindingFlags.SYNC_CREATE);
			place.bind_property ("icon", icon, "icon-name", BindingFlags.SYNC_CREATE);
			place.bind_property ("visible", this, "visible", BindingFlags.SYNC_CREATE);
			place.bind_property ("selectable", this, "selectable", BindingFlags.SYNC_CREATE);
			place.bind_property ("badge", badge, "label", BindingFlags.SYNC_CREATE);
			place.bind_property ("badge", badge, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				target.set_boolean (src.get_int () > 0);
				return true;
			});

			place.notify["needs-attention"].connect (on_attention_change);
			on_attention_change ();
		}

		// ListBox's bind_model sets visibility of every row to true
		// when the model changes. Let's do some hacking around it.
		void on_visibility_changed () {
			if (this.visible != this.place.visible) this.visible = this.place.visible;
		}

		void on_attention_change () {
			if (this.place.needs_attention) {
				badge.remove_css_class ("no-attention");
			} else {
				badge.add_css_class ("no-attention");
			}
		}
	}

	Gtk.Widget on_item_create (Object obj) {
		return new ItemRow (obj as Place);
	}

	[GtkCallback] void on_item_activated (Gtk.ListBoxRow _row) {
		var row = _row as ItemRow;
		if (row.place.open_func != null)
			row.place.open_func (app.main_window, row.place.extra_data);

		var split_view = app.main_window.split_view;
		if (split_view.collapsed)
			split_view.show_sidebar = false;
	}

	void on_item_header_update (Gtk.ListBoxRow _row, Gtk.ListBoxRow? _before) {
		var row = _row as ItemRow;
		var before = _before as ItemRow;

		row.set_header (null);

		if (row.place.separated && before != null && !before.place.separated) {
			row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL) {
				css_classes = { "ttl-separator" }
			});
		}
	}

	void view_announcements_cb () {
		app.open_announcements ();
	}

	void view_fr_cb () {
		app.open_follow_requests ();
	}

	// Account
	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
		static construct {
			typeof (Widgets.Avatar).ensure ();
		}

		public InstanceAccount? account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Gtk.Button forget;
		[GtkChild] unowned Gtk.Label notifications_badge;

		public signal void popdown_signal ();

		private Binding switcher_display_name;
		private Binding switcher_handle;
		private Binding switcher_tooltip;
		private Binding switcher_avatar;
		private Binding switcher_notifications;
		private Binding switcher_notifications_visibility;
		public AccountRow (InstanceAccount? _account) {
			if (account != null) {
				switcher_display_name.unbind ();
				switcher_handle.unbind ();
				switcher_tooltip.unbind ();
				switcher_avatar.unbind ();
				switcher_notifications.unbind ();
				switcher_notifications_visibility.unbind ();
			}

			account = _account;
			if (account != null) {
				switcher_display_name = this.account.bind_property ("display-name", this, "title", BindingFlags.SYNC_CREATE);
				switcher_handle = this.account.bind_property ("handle", this, "subtitle", BindingFlags.SYNC_CREATE);
				switcher_tooltip = this.account.bind_property ("handle", this, "tooltip-text", BindingFlags.SYNC_CREATE);
				switcher_avatar = this.account.bind_property ("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
				switcher_notifications = this.account.bind_property ("unread-count", notifications_badge, "label", BindingFlags.SYNC_CREATE);
				switcher_notifications_visibility = this.account.bind_property ("unread-count", notifications_badge, "visible", BindingFlags.SYNC_CREATE, switcher_notifications_visibility_cb);
			} else {
				title = _("Add Account");
				avatar.account = null;
				selectable = false;
				forget.hide ();
				tooltip_text = _("Add Account");
				avatar.icon_name = "tuba-plus-large-symbolic";
				avatar.remove_css_class ("flat");
			}
		}

		bool switcher_notifications_visibility_cb (Binding binding, Value from_value, ref Value to_value) {
			to_value.set_boolean (from_value.get_int () > 0);
			return true;
		}

		[GtkCallback] void on_open () {
			if (account != null) {
				account.resolve_open (accounts.active);
			} else {
				new Dialogs.NewAccount (true).present ();
			}
			popdown_signal ();
		}

		[GtkCallback] void on_forget () {
			popdown_signal ();
			app.question.begin (
				// translators: the variable is an account handle
				{_("Forget %s?").printf ("<span segment=\"word\">@%s</span><span segment=\"word\">@%s</span>".printf (account.username, account.domain)), true},
				{_("This account will be removed from the application."), false},
				app.main_window,
				{ { _("Forget"), Adw.ResponseAppearance.DESTRUCTIVE }, { _("Cancel"), Adw.ResponseAppearance.DEFAULT } },
				null,
				false,
				(obj, res) => {
					if (app.question.end (res).truthy ()) {
						try {
							accounts.remove (account);
						} catch (Error e) {
							warning (e.message);
							app.toast ("%s: %s".printf (_("Error"), e.message));
						}
					}
				}
			);
		}

	}

	void popdown () {
		account_switcher_popover_menu.popdown ();
	}

	void on_account_header_update (Gtk.ListBoxRow _row, Gtk.ListBoxRow? _before) {
		var row = _row as AccountRow;

		row.set_header (null);

		if (row.account == null && _before != null)
			row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
	}

	[GtkCallback] void on_account_activated (Gtk.ListBoxRow _row) {
		popdown ();

		var row = _row as AccountRow;
		if (row.account != null)
			accounts.activate (row.account, true);
		else
			new Dialogs.NewAccount (true).present ();
	}
}
