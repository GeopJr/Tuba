[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/view.ui")]
public class Tuba.Views.Sidebar : Gtk.Widget, AccountHolder {
	[GtkChild] unowned Gtk.ListBox items;
	[GtkChild] unowned Gtk.ListBox saved_accounts;
	[GtkChild] unowned Widgets.Avatar accounts_button_avi;
	[GtkChild] unowned Gtk.MenuButton menu_btn;
	[GtkChild] unowned Gtk.Popover account_switcher_popover_menu;

	protected InstanceAccount? account { get; set; default = null; }

	protected GLib.ListStore app_items;
	protected Gtk.SliceListModel account_items;
	protected Gtk.FlattenListModel item_model;

	static construct {
		typeof (Widgets.EmojiLabel).ensure ();
		set_layout_manager_type (typeof (Gtk.BinLayout));
	}

	construct {
		var menu_model = new GLib.Menu ();

		var account_submenu_model = new GLib.Menu ();
		account_submenu_model.append (_("Open Profile"), "app.open-current-account-profile");
		account_submenu_model.append (_("Refresh"), "app.refresh");
		menu_model.append_section (null, account_submenu_model);

		var misc_submenu_model = new GLib.Menu ();
		misc_submenu_model.append (_("Preferences"), "app.open-preferences");
		misc_submenu_model.append (_("Keyboard Shortcuts"), "win.show-help-overlay");
		misc_submenu_model.append (_("About"), "app.about");
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
	}

	protected virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
		var w = saved_accounts.get_first_child ();
		while (w != null) {
			saved_accounts.remove (w);
			w = saved_accounts.get_first_child ();
		}

		accounts.foreach (acc => {
			AccountRow row = new AccountRow (acc);
			saved_accounts.append (row);
			if (acc.handle == this.account.handle)
				saved_accounts.select_row (row);

			return true;
		});

		var new_acc_row = new AccountRow (null) {
			css_classes = { "new-account" }
		};
		saved_accounts.append (new_acc_row);
	}

	public void set_sidebar_selected_item (int index) {
		if (items != null) {
			items.select_row (items.get_row_at_index (index));
		}
	}

	private Binding sidebar_avatar_btn;
	protected virtual void on_account_changed (InstanceAccount? account) {
		if (this.account != null) {
			sidebar_avatar_btn.unbind ();
		}

		if (app?.main_window != null)
			app.main_window.go_back_to_start ();

		this.account = account;

		if (account != null) {
			sidebar_avatar_btn = this.account.bind_property ("avatar", accounts_button_avi, "avatar-url", BindingFlags.SYNC_CREATE);
			account_items.model = account.known_places;
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
			place.bind_property ("badge", badge, "label", BindingFlags.SYNC_CREATE);
			place.bind_property ("badge", badge, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				target.set_boolean (src.get_int () > 0);
				return true;
			});

			place.bind_property ("selectable", this, "selectable", BindingFlags.SYNC_CREATE);
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



	// Account
	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
		public InstanceAccount? account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Gtk.Button forget;

		private Binding switcher_display_name;
		private Binding switcher_handle;
		private Binding switcher_tooltip;
		private Binding switcher_avatar;
		public AccountRow (InstanceAccount? _account) {
			if (account != null) {
				switcher_display_name.unbind ();
				switcher_handle.unbind ();
				switcher_tooltip.unbind ();
				switcher_avatar.unbind ();
			}

			account = _account;
			if (account != null) {

				switcher_display_name = this.account.bind_property ("display-name", this, "title", BindingFlags.SYNC_CREATE);
				switcher_handle = this.account.bind_property ("handle", this, "subtitle", BindingFlags.SYNC_CREATE);
				switcher_tooltip = this.account.bind_property ("handle", this, "tooltip-text", BindingFlags.SYNC_CREATE);
				switcher_avatar = this.account.bind_property ("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
			}
			else {
				title = _("Add Account");
				avatar.account = null;
				selectable = false;
				forget.hide ();
				tooltip_text = _("Add Account");
			}
		}

		[GtkCallback] void on_open () {
			if (account != null) {
				account.resolve_open (accounts.active);
			}
		}

		[GtkCallback] void on_forget () {
			// The String#replace below replaces the @ with <zero-width>@
			// so it wraps cleanly

			var confirmed = app.question (
				// translators: the variable is an account handle
				_("Forget %s?").printf (account.handle.replace ("@", "​@")),
				_("This account will be removed from the application."),
				app.main_window,
				_("Forget"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect (res => {
				if (res == "yes") {
					try {
						accounts.remove (account);
					}
					catch (Error e) {
						warning (e.message);
						var dlg = app.inform (_("Error"), e.message);
						dlg.present ();
					}
				}
				confirmed.destroy ();
			});

			confirmed.present ();
		}

	}

	void on_account_header_update (Gtk.ListBoxRow _row, Gtk.ListBoxRow? _before) {
		var row = _row as AccountRow;

		row.set_header (null);

		if (row.account == null && _before != null)
			row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
	}

	[GtkCallback] void on_account_activated (Gtk.ListBoxRow _row) {
		account_switcher_popover_menu.popdown ();

		var row = _row as AccountRow;
		if (row.account != null)
			accounts.activate (row.account);
		else
			new Dialogs.NewAccount ().present ();
	}

}
