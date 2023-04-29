using Gtk;

[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/view.ui")]
public class Tuba.Views.Sidebar : Box, AccountHolder {

	[GtkChild] unowned ToggleButton accounts_button;
	[GtkChild] unowned Stack mode;
	[GtkChild] unowned ListBox items;
	[GtkChild] unowned ListBox saved_accounts;

	[GtkChild] unowned Widgets.Avatar avatar;
	[GtkChild] unowned Widgets.EmojiLabel title;
	[GtkChild] unowned Label subtitle;

	protected InstanceAccount? account { get; set; default = null; }

	protected GLib.ListStore app_items;
	protected SliceListModel account_items;
	protected FlattenListModel item_model;

	public static Place PREFERENCES = new Place () {
			title = _("Preferences"),
			icon = "tuba-gear-symbolic",
			selectable = false,
			separated = true,
			open_func = () => {
				Dialogs.Preferences.open ();
			}
	};
	public static Place ABOUT = new Place () {
			title = _("About"),
			icon = "tuba-about-symbolic",
			selectable = false,
			open_func = () => {
				app.lookup_action ("about").activate (null);
			}
	};

	construct {
		app_items = new GLib.ListStore (typeof (Place));
		app_items.append (PREFERENCES);
		app_items.append (ABOUT);

		account_items = new SliceListModel (null, 0, 15);

		var models = new GLib.ListStore (typeof (Object));
		models.append (account_items);
		models.append (app_items);
		item_model = new FlattenListModel (models);

		items.bind_model (item_model, on_item_create);
		items.set_header_func (on_item_header_update);
		saved_accounts.set_header_func (on_account_header_update);

		construct_account_holder ();
	}

	protected virtual void on_accounts_changed (Gee.ArrayList<InstanceAccount> accounts) {
		var w = saved_accounts.get_first_child ();
		while(w != null) {
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

	public void set_sidebar_selected_item(int index) {
		if (items != null) {
			items.select_row(items.get_row_at_index(index));
		}
	}

	private Binding sidebar_handle_short;
	private Binding sidebar_avatar;
	private ulong sidebar_private_signal;
	private Binding sidebar_display_name;
	protected virtual void on_account_changed (InstanceAccount? account) {
		if (this.account != null) {
			sidebar_handle_short.unbind();
			sidebar_avatar.unbind();
			this.account.disconnect(sidebar_private_signal);
			sidebar_display_name.unbind ();
		}

		if (app?.main_window != null)
			app.main_window.go_back_to_start ();

		this.account = account;
		accounts_button.active = false;

		if (account != null) {
			sidebar_private_signal = this.account.notify["locked"].connect(() => {
				uint indx;
				var found = this.account.known_places.find (Mastodon.Account.PLACE_FOLLOW_REQUESTS, out indx);

				if (this.account.locked == false && found == true) {
					this.account.known_places.remove(indx);
				} else if (this.account.locked == true && found == false) {
					this.account.known_places.append(Mastodon.Account.PLACE_FOLLOW_REQUESTS);
				}
			});

			sidebar_handle_short = this.account.bind_property("handle_short", subtitle, "label", BindingFlags.SYNC_CREATE);
			sidebar_avatar = this.account.bind_property("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
			sidebar_display_name = this.account.bind_property("display-name", title, "content", BindingFlags.SYNC_CREATE, (b, src, ref target) => {
				title.instance_emojis = this.account.emojis_map;
				target.set_string (src.get_string ());
				return true;
			});

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

		var flap = app.main_window.flap;
        if (flap.folded)
			flap.reveal_flap = false;
	}


	// Item

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/item.ui")]
	protected class ItemRow : ListBoxRow {
		public Place place;

		[GtkChild] unowned Image icon;
		[GtkChild] unowned Label label;
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

	Widget on_item_create (Object obj) {
		return new ItemRow (obj as Place);
	}

	[GtkCallback] void on_item_activated (ListBoxRow _row) {
		var row = _row as ItemRow;
		if (row.place.open_func != null)
			row.place.open_func (app.main_window);

        var flap = app.main_window.flap;
        if (flap.folded)
			flap.reveal_flap = false;
	}

	void on_item_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as ItemRow;
		var before = _before as ItemRow;

		row.set_header (null);

		if (row.place.separated && before != null && !before.place.separated) {
			row.set_header (new Separator (Orientation.HORIZONTAL));
		}
	}



	// Account

	[GtkTemplate (ui = "/dev/geopjr/Tuba/ui/views/sidebar/account.ui")]
	protected class AccountRow : Adw.ActionRow {
		public InstanceAccount? account;

		[GtkChild] unowned Widgets.Avatar avatar;
		[GtkChild] unowned Button forget;

		private Binding switcher_display_name;
		private Binding switcher_handle;
		private Binding switcher_avatar;
		public AccountRow (InstanceAccount? _account) {
			if (account != null) {
				switcher_display_name.unbind();
				switcher_handle.unbind();
				switcher_avatar.unbind();
			}

			account = _account;
			if (account != null) {
				
				switcher_display_name = this.account.bind_property("display-name", this, "title", BindingFlags.SYNC_CREATE);
				switcher_handle = this.account.bind_property("handle", this, "subtitle", BindingFlags.SYNC_CREATE);
				switcher_avatar = this.account.bind_property("avatar", avatar, "avatar-url", BindingFlags.SYNC_CREATE);
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
				_("Forget %s?".printf (account.handle)),
				_("This account will be removed from the application."),
				app.main_window,
				_("Forget"),
				Adw.ResponseAppearance.DESTRUCTIVE
			);

			confirmed.response.connect(res => {
				if (res == "yes") {
					try {
						accounts.remove (account);
					}
					catch (Error e) {
						warning (e.message);
						app.inform (Gtk.MessageType.ERROR, _("Error"), e.message);
					}
				}
				confirmed.destroy();
			});

			confirmed.present ();
		}

	}

	void on_account_header_update (ListBoxRow _row, ListBoxRow? _before) {
		var row = _row as AccountRow;

		row.set_header (null);

		if (row.account == null && _before != null)
			row.set_header (new Separator (Orientation.HORIZONTAL));
	}

	[GtkCallback] void on_account_activated (ListBoxRow _row) {
		var row = _row as AccountRow;
		if (row.account != null)
			accounts.activate (row.account);
		else
			new Dialogs.NewAccount ().present ();
	}

}
