[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/view.ui")]
public class Tuba.Views.Sidebar : Gtk.Box, AccountHolder {

	[GtkChild] unowned Gtk.ToggleButton accounts_button;
	[GtkChild] unowned Gtk.Stack mode;
	[GtkChild] unowned Gtk.ListBox items;
	[GtkChild] unowned Gtk.ListBox saved_accounts;

	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Widgets.EmojiLabel title;
	[GtkChild] unowned Gtk.Label subtitle;

	protected InstanceAccount? account { get; set; default = null; }

	protected GLib.ListStore app_items;
	protected Gtk.SliceListModel account_items;
	protected Gtk.FlattenListModel item_model;

	public static Place KEYBOARD_SHORTCUTS = new Place () { // vala-lint=naming-convention

		icon = "input-keyboard-symbolic",
		title = _("Keyboard Shortcuts"),
		selectable = false,
		open_func = () => {
			app.main_window.lookup_action ("show-help-overlay").activate (null);
		}
	};
	public static Place PREFERENCES = new Place () { // vala-lint=naming-convention

			icon = "tuba-gear-symbolic",
			title = _("Preferences"),
			selectable = false,
			separated = true,
			open_func = () => {
				Dialogs.Preferences.open ();
			}
	};
	public static Place ABOUT = new Place () { // vala-lint=naming-convention

			icon = "tuba-about-symbolic",
			title = _("About"),
			selectable = false,
			open_func = () => {
				app.lookup_action ("about").activate (null);
			}
	};

	static construct {
		typeof (Widgets.EmojiLabel).ensure ();
	}

	construct {
		app_items = new GLib.ListStore (typeof (Place));
		app_items.append (PREFERENCES);
		app_items.append (KEYBOARD_SHORTCUTS);
		app_items.append (ABOUT);

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
			saved_accounts.append (new AccountRow (acc));
			return true;
		});

		var new_acc_row = new AccountRow (null);
		saved_accounts.append (new_acc_row);
	}

	public void set_sidebar_selected_item (int index) {
		if (items != null) {
			items.select_row (items.get_row_at_index (index));
		}
	}

	private Binding sidebar_handle_short;
	private Binding sidebar_avatar;
	private Binding sidebar_display_name;
	protected virtual void on_account_changed (InstanceAccount? account) {
		if (this.account != null) {
			sidebar_handle_short.unbind ();
			sidebar_avatar.unbind ();
			sidebar_display_name.unbind ();
		}

		if (app?.main_window != null)
			app.main_window.go_back_to_start ();

		this.account = account;
		accounts_button.active = false;

		if (account != null) {
			sidebar_handle_short = this.account.bind_property ("handle_short", subtitle, "label", BindingFlags.SYNC_CREATE);
			sidebar_avatar = this.account.bind_property ("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
			sidebar_display_name = this.account.bind_property (
				"display-name",
				title,
				"content",
				BindingFlags.SYNC_CREATE,
				(b, src, ref target) => {
					title.instance_emojis = this.account.emojis_map;
					target.set_string (src.get_string ());
					return true;
				}
			);

			account_items.model = account.known_places;
		} else {
			saved_accounts.unselect_all ();

			title.content = _("Anonymous");
			subtitle.label = _("No account selected");
			avatar.account = null;
			account_items.model = null;
		}
	}

	[GtkCallback] void on_mode_changed () {
		mode.visible_child_name = accounts_button.active ? "saved_accounts" : "items";
	}

	[GtkCallback] void on_open () {
		if (account == null) return;
		account.open ();

        var split_view = app.main_window.split_view;
        if (split_view.collapsed)
			split_view.show_sidebar = false;
	}


	// Item

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/item.ui")]
	protected class ItemRow : Gtk.ListBoxRow {
		public Place place;

		[GtkChild] unowned Gtk.Image icon;
		[GtkChild] unowned Gtk.Label label;
		//  [GtkChild] unowned Label badge;

		public ItemRow (Place place) {
			this.place = place;
			place.bind_property ("title", label, "label", BindingFlags.SYNC_CREATE);
			place.bind_property ("icon", icon, "icon-name", BindingFlags.SYNC_CREATE);
			//  place.bind_property ("badge", badge, "label", BindingFlags.SYNC_CREATE);
			//  place.bind_property ("badge", badge, "visible", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
			//  	target.set_boolean (src.get_int () > 0);
			//  	return true;
			//  });

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
			row.set_header (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
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
			}
		}

		[GtkCallback] void on_open () {
			if (account != null) {
				account.resolve_open (accounts.active);
			}
		}

		[GtkCallback] void on_forget () {
			var confirmed = app.question (
				// translators: the variable is an account handle
				_("Forget %s?".printf (account.handle)),
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
		var row = _row as AccountRow;
		if (row.account != null)
			accounts.activate (row.account);
		else
			new Dialogs.NewAccount ().present ();
	}

}
