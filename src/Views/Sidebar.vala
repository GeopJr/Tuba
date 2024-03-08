[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/view.ui")]
public class Tuba.Views.Sidebar : Gtk.Widget, AccountHolder {
	[GtkChild] unowned Gtk.ListBox items;
	[GtkChild] unowned Gtk.ListBox saved_accounts;
	[GtkChild] unowned Widgets.Avatar accounts_button_avi;
	[GtkChild] unowned Gtk.MenuButton menu_btn;
	[GtkChild] unowned Gtk.Popover account_switcher_popover_menu;
	[GtkChild] unowned Adw.Banner banner;

	protected InstanceAccount? account { get; set; default = null; }

	protected GLib.ListStore app_items;
	protected Gtk.SliceListModel account_items;
	protected Gtk.FlattenListModel item_model;
	protected GLib.ListStore accounts_model;

	public int unread_announcements {
		set {
			if (value > 0) {
				banner.revealed = true;
				// tanslators: used in a banner, the variable is the number of unread announcements
				banner.title = GLib.ngettext ("%d Announcement", "%d Announcements", (ulong) value).printf (value);
			} else {
				banner.revealed = false;
			}
		}
	}

	static construct {
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
		misc_submenu_model.append (_("Mutes & Blocks"), "app.open-mutes-blocks");
		menu_model.append_section (null, misc_submenu_model);

		misc_submenu_model = new GLib.Menu ();
		misc_submenu_model.append (_("Preferences"), "app.open-preferences");
		misc_submenu_model.append (_("Keyboard Shortcuts"), "win.show-help-overlay");
		misc_submenu_model.append (_("About %s").printf (Build.NAME), "app.about");
		menu_model.append_section (null, misc_submenu_model);

		menu_btn.menu_model = menu_model;

		app_items = new GLib.ListStore (typeof (Place));
		account_items = new Gtk.SliceListModel (null, 0, 15);

		var models = new GLib.ListStore (typeof (Object));
		models.append (account_items);
		models.append (app_items);
		item_model = new Gtk.FlattenListModel (models);

		items.bind_model (item_model, on_item_create);
		items.set_header_func (on_item_header_update);
		saved_accounts.set_header_func (on_account_header_update);

		construct_account_holder ();
		banner.button_clicked.connect (view_announcements_cb);
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
	private Binding announcements_banner;
	protected virtual void on_account_changed (InstanceAccount? account) {
		if (this.account != null) {
			sidebar_avatar_btn.unbind ();
			announcements_banner.unbind ();
		}
		unread_announcements = 0;

		if (app?.main_window != null)
			app.main_window.go_back_to_start ();

		this.account = account;

		if (account != null) {
			announcements_banner = this.account.bind_property ("unread-announcements", this, "unread-announcements", BindingFlags.SYNC_CREATE);
			sidebar_avatar_btn = this.account.bind_property ("avatar", accounts_button_avi, "avatar-url", BindingFlags.SYNC_CREATE);
			account_items.model = account.known_places;
			update_selected_account ();
		} else {
			saved_accounts.unselect_all ();

			account_items.model = null;
			accounts_button_avi.account = null;
		}
	}

	// Item
	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/item.ui")]
	protected class ItemRow : Gtk.ListBoxRow {
		public Place place;

		[GtkChild] unowned Gtk.Image icon;
		[GtkChild] unowned Gtk.Label label;
		[GtkChild] unowned Gtk.Label badge;

		public ItemRow (Place place) {
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
			row.place.open_func (app.main_window);

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

	// Account
	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
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
				new Dialogs.NewAccount ().present ();
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
			new Dialogs.NewAccount ().present ();
	}
}
